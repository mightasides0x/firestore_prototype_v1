# Architecture Overview

## 1. Directory Structure Overview

```
lib/
├── app/                      # Core MaterialApp, Routing, Global Providers
│   ├── app.dart
│   └── app_router.dart
│
├── core/                # Shared code used across features
│   ├── constants/       # App-wide constants (strings, numbers, keys)
│   ├── di/              # Dependency injection setup/configuration
│   ├── error/           # Custom exception/failure classes & handling
│   ├── models/          # Core data models (if truly cross-feature)
│   ├── navigation/      # Navigation helpers/router configuration
│   ├── theme/           # App theme data (colors, typography)
│   └── utils/           # Utility functions, extensions, mixins
│
├── features/                 
│   │
│   ├── auth/                 # F-AUTH-01
│   │   ├── data/             # Datasources (Firebase Auth, Firestore User), Models, Repositories Impl
│   │   ├── domain/           # Entities, Repositories (Abstract), Usecases
│   │   └── presentation/     # Blocs/Cubits, Screens, Widgets
│   │
│   ├── home/                 # F-TOPIC-01 (Display), Auth Status/Logout
│   │   ├── data/             # Datasources (Firestore Topics), Models, Repositories Impl
│   │   ├── domain/           # Entities, Repositories (Abstract), Usecases
│   │   └── presentation/     # Blocs/Cubits, Screens, Widgets
│   │
│   ├── matchmaking/          # F-MATCH-01 (Initiation from Home)
│   │   ├── data/             # Datasources (Firestore Matchmaking Pool/Game Creation), Models, Repositories Impl
│   │   ├── domain/           # Entities, Repositories (Abstract), Usecases
│   │   └── presentation/     # Blocs/Cubits, Widgets (e.g., Waiting Indicator)
│   │
│   └── game/                 # F-GAME-01, F-RESULT-01
│       ├── data/             # Datasources (Firestore Game State/Questions), Models, Repositories Impl
│       ├── domain/           # Entities, Repositories (Abstract), Usecases
│       └── presentation/     # Blocs/Cubits, Screens (Game, Results), Widgets
│
└── main.dart                 # App entry point
```



## 2. Layered Architecture Overview

The application follows a layered architecture:

```
+-------------------+      +--------------------------+      +----------------------+      +-----------------+
|      UI Layer     | ---> | State Management Layer   | ---> | Data Layer           | ---> | Data Sources    |
| (Flutter Widgets) |      | (Cubits/Blocs)           |      | (Repositories)       |      | (Firebase SDKs) |
+-------------------+      +--------------------------+      +----------------------+      +-----------------+
        |                                                            ^
        | User Events                                                | Data Flow
        V                                                            |
+-------------------+
|   State Updates   | <----------------------------------------------+
+-------------------+
```

*   UI Layer:
    *   Responsibility: Renders the user interface based on the current state provided by the State Management Layer. Captures user input and forwards events to the State Management Layer.
    *   Technology: Flutter Widgets (StatelessWidget, StatefulWidget), Material Design components.
    *   Interaction: Uses Bloc widgets and extensions, e.g. `BlocProvider` to access state management logic, `BlocBuilder` / `BlocSelector` to rebuild UI parts based on state changes, and `BlocListener` to trigger side-effects like navigation or showing dialogs/snackbars.

*   State Management Layer:
    *   Responsibility: Manages the state of UI components. Processes user events received from the UI Layer. Interacts with the Data Layer (Repositories) to fetch or modify data. Contains the presentation logic.
    *   Technology: `flutter_bloc` package (primarily `Cubit`, potentially `Bloc` for more complex scenarios).
    *   Interaction: Holds application state. Exposes streams of states for the UI to consume. Calls methods on Repository interfaces. Handles errors originating from the Data Layer and updates the state accordingly.

*   Data Layer (Repositories):
    *   Responsibility: Abstract the origin and implementation details of data sources. Provides a clean API for the State Management Layer to access data. Handles data fetching, mapping (e.g., from Firestore documents to domain models), and potentially basic caching logic.
    *   Technology: Abstract Dart classes (Interfaces) defining contracts, Concrete implementation classes (`RepositoryImpl`).
    *   Interaction: Interfaces are defined (often within the feature module). Implementations interact directly with Data Sources (e.g., Firebase SDKs). Consumed by the State Management Layer via Dependency Injection.

*   Data Sources:
    *   Responsibility: Direct interaction with external data providers like backend APIs or databases.
    *   Technology: Firebase SDKs (`firebase_auth`, `cloud_firestore`), potentially `http` package for future REST APIs.
    *   Interaction: Called by the concrete Repository implementations.

## 3. 

## 4. State Management (Cubit/Bloc)

*   Choice: `flutter_bloc` is used for predictable state management. `Cubit` is preferred for simpler logic where events are direct method calls. `Bloc` may be used for more complex features with multiple distinct event types leading to state changes.
*   State: States should be immutable classes. Use `copyWith` for generating new state instances.
*   Events: (For Bloc) Represent user actions or system events as distinct classes.
*   Interaction: Cubits/Blocs are provided to the widget tree using `BlocProvider`. UI elements listen and rebuild using `BlocBuilder` or `BlocSelector`. Side effects (navigation, dialogs) are handled using `BlocListener`. Cubits/Blocs interact with repositories via injected dependencies.

## 5. Data Handling (Repository Pattern)

*   Purpose: Decouples the rest of the application (especially state management) from the specifics of data fetching and storage (Firestore). Facilitates testing by allowing mock repositories.
*   Structure:
    *   Interface: An abstract class defined in the `domain/repository/` sub-directory of a feature, outlining the contract (methods).
    *   Implementation: A concrete class in the `data/repositories/` sub-directory that implements the interface, using specific data sources (e.g., Firestore SDK).
*   Models: Data structures representing entities (e.g., `User`, `Topic`, `Game`) are defined, typically within the `domain/entities/` or `data/models/` directories. These are used for communication between layers. (Consider creating `docs/DATA_MODELS.md` for detailed definitions).

## 6. Dependency Injection (DI)

*   Tool: The `flutter_bloc` package (`RepositoryProvider`, `BlocProvider`) is used for DI.
*   Strategy: Repositories are provided higher up in the widget tree (often near the `MaterialApp` or feature root) using `RepositoryProvider`. Cubits/Blocs that depend on these repositories are then provided using `BlocProvider`, typically closer to the UI components that need them. `context.read<T>()` is used to access dependencies within Cubits/Blocs or for one-off access in UI event handlers.

## 7. Navigation

*   Approach: (Describe the chosen approach, e.g., Navigator 2.0 with GoRouter, AutoRoute, or standard Navigator 1.0 push/pop methods).
*   Triggering: Navigation is typically triggered as a side-effect in response to state changes, often using `BlocListener` in the UI layer based on signals from the Cubit/Bloc (e.g., `navigateToGameScreen` state flag).

## 8. Error Handling

*   Flow: Data source errors (e.g., network issues, Firestore exceptions) are caught within Repository implementations.
*   Representation: Repositories typically return a type that represents success or failure (e.g., using `Either` from `fpdart` or a custom `Result` class) or throw custom exceptions.
*   Management: Cubits/Blocs receive these results/exceptions, update their state to reflect the error (e.g., `MyState.error(message)`), and optionally perform logging.
*   Presentation: The UI layer listens to error states via `BlocBuilder` or `BlocListener` and displays appropriate feedback (e.g., Snackbars, Dialogs, error messages within the UI).

## 9. Testing Guidelines

*   **Directory Structure:** Maintain a parallel structure within the `test` directory:
    ```
    test/
      └── features/
          └── feature_name/
              ├── application/ # Renamed from presentation/cubit
              │   └── feature_name_cubit_test.dart
              ├── domain/
              │   ├── usecases/
              │   │   └── some_use_case_test.dart
              │   └── entities/ # Tests if complex entity logic exists
              │       └── some_entity_test.dart
              ├── data/ # Renamed from infrastructure
              │   ├── repositories/
              │   │   └── feature_name_repository_impl_test.dart
              │   ├── datasources/
              │   │   └── feature_name_remote_data_source_test.dart
              │   └── models/ # Renamed from dtos
              │       └── feature_name_dto_test.dart # Primarily for fromJson/toJson
              └── presentation/
                  ├── view/ # Renamed from pages/screens
                  │   └── feature_name_page_test.dart # Widget test for screen
                  └── widgets/
                      └── specific_widget_test.dart # Widget test for specific widget
      └── core/
          └── utils/
              └── some_util_test.dart
    ```

*   **Testing Requirements:**
    *   All business logic (use cases, complex entity logic) must have **unit tests**.
    *   State management classes (Cubits/Blocs) must have **unit tests** (using `bloc_test`).
    *   Repository implementations and data sources should have **unit tests** (mocking external dependencies like HTTP clients or databases/Firestore).
    *   All significant widgets and pages/screens must have **widget tests**.
    *   Mock all external dependencies (network calls, database access, platform channels) in unit and widget tests.
    *   Test files should mirror the source code structure within the `test` directory.

*   **Testing Conventions:**
    *   Test files must end with `_test.dart`.
    *   Use meaningful `group()` descriptions and test case (`test()` or `testWidgets()`) names outlining the scenario and expected outcome.
    *   Each test case should focus on verifying a single behavior or aspect.
    *   Maintain test independence: tests should not rely on the state or outcome of previous tests. Use `setUp` and `tearDown` (or `setUpAll`/`tearDownAll`) appropriately.

*   **Testability Guidelines:**
    *   Keep UI logic minimal in widgets; delegate complexity to state management (Cubits/Blocs) or domain layer.
    *   Avoid static methods/classes for core logic that needs mocking or testing; prefer dependency injection.
    *   Use interfaces (abstract classes) for external services/repositories to allow easy mocking.
    *   Provide `Key` properties (`ValueKey`, `GlobalKey`) for important UI elements that need to be found or interacted with in widget tests.

## 10. Naming Conventions

### Files and Directories

1.  All file and directory names should use **snake_case**.
2.  Feature directories should be descriptive and domain-specific (e.g., `user_profile`, `order_history`).
3.  Interface files (defining abstract classes) should be named after the abstract class they define (e.g., `auth_repository.dart` for `abstract class AuthRepository`).
4.  State management files should use the suffix matching their type:
    *   Cubit files: `_cubit.dart` (e.g., `login_cubit.dart`)
    *   State files: `_state.dart` (e.g., `login_state.dart`)
5.  Domain Entity files should be named after the primary entity class they contain (e.g., `user.dart` for `User`).
6.  Data Model/DTO files should use the suffix `_model.dart` or `_dto.dart` (e.g., `user_profile_model.dart`, `user_profile_dto.dart`).
7.  Widget files should generally be named after the primary widget class they contain (e.g., `login_button.dart` for `LoginButton`). A `_widget.dart` suffix is acceptable if preferred for explicitness.
8.  Constant files should have descriptive names (e.g., `app_constants.dart`, `sizes.dart`).

### Classes

1.  Use **PascalCase** for class names.
2.  Widget classes should match their file names in PascalCase (e.g., `LoginButton` in `login_button.dart`).
3.  Interface classes (defined using `abstract class`) should **not** have a special prefix (e.g., `AuthRepository`, not `IAuthRepository`).
4.  State classes should be suffixed with `State` (e.g., `LoginSuccessState`).
5.  Cubit classes should be suffixed with `Cubit` (e.g., `LoginCubit`).
6.  Constant classes should be prefixed with `K` or be descriptive (e.g., `KSizes`, `AppConstants`).

### Layout Constants (e.g., KSizes, AppSizes)

1.  All UI measurements *must* use predefined constants from a central constants file (e.g., `core/constants/sizes.dart` containing a `KSizes` or `AppSizes` class).
    *   Margins and padding (e.g., `KSizes.padding4`, `KSizes.padding8`)
    *   Font sizes (e.g., `KSizes.fontSizeSmall`, `KSizes.fontSizeMedium`)
    *   Border radius (e.g., `KSizes.borderRadiusDefault`)
    *   Icon sizes (e.g., `KSizes.iconSizeSmall`, `KSizes.iconSizeMedium`)
    *   Component sizes (e.g., `KSizes.buttonHeightDefault`)
2.  **Never** use hard-coded numeric values directly in the UI code for:
    *   Spacing and layout (padding, margins, SizedBox dimensions)
    *   Typography (font sizes)
    *   Component dimensions or constraints
    *   Border radius values
3.  The constants class (e.g., `KSizes`) should follow a consistent scaling system or semantic naming:
    *   Base unit multiplication (e.g., base unit 4.0 -> `size4`, `size8`, `size12`)
    *   Semantic naming (e.g., `small`, `medium`, `large` for fonts, icons, padding)
4.  All new layout-related constants *must* be added to the central constants class for discoverability and reusability. Constants *within* these files may use a `k` prefix (e.g., `kDefaultPadding`).

## 11. Code Style & Best Practices

1.  **Code Organization:** Adhere to the directory structure outlined in Section 3. Core, shared functionality should reside in the `core/` directory.
2.  **Widget Structure:**
    *   Main feature widgets/screens may be `StatefulWidget` if managing local UI state not suited for a Cubit/Bloc (e.g., animations, controllers), but prefer `StatelessWidget` driven by a Cubit/Bloc where possible.
    *   Smaller, reusable UI components should preferably be `StatelessWidget`.
    *   Each significant widget should ideally be in its own file for clarity and ease of testing.
    *   Test-related widget components or methods intended only for testing should be marked with `@visibleForTesting`.
3.  **General Practices:**
    *   Keep widget files focused on a single responsibility (rendering UI based on input/state).
    *   Maintain a clear separation between presentation logic (in widgets/cubits) and business logic (in domain/use cases).
    *   Follow a consistent pattern for state management implementation (e.g., using Cubit/Bloc provider, listening/building).
    *   Define interfaces (abstract classes) for external dependencies (repositories, services) and depend on these abstractions.
    *   All core business logic (domain layer) should be pure Dart, testable, and independent of the UI framework (Flutter).