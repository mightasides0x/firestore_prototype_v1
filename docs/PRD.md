# Product Requirements Document (PRD)

## 1. Introduction

This document outlines the requirements for the Minimum Viable Product (MVP) of a real-time, head-to-head mobile quiz application, similar in core concept to QuizUp. The MVP focuses on validating the core gameplay loop: user authentication, topic selection, matchmaking, real-time quiz experience, and results display. The application will be built using Flutter for the frontend and Cloud Firestore (with Firebase Authentication) for the backend. State management will primarily use the Cubit/BLoC pattern.

## 2. Goals

*   **Validate Core Gameplay Loop:** Demonstrate that users can successfully sign up/log in, select a topic, get matched with another player, play a quiz in near real-time, and view the results.
*   **Test Technical Feasibility:** Confirm the viability of Cloud Firestore for handling real-time game state synchronization with acceptable latency for this use case.
*   **Prove Architectural Soundness:** Validate the chosen architecture (Flutter, Firestore, Cubit/BLoC, Repository Pattern, Feature-first structure) as a foundation for future development.
*   **Gather Early User Feedback:** Collect initial feedback on the core user experience and identify major pain points or desired improvements.

## 3. Target Audience

*   Early Adopters interested in new mobile games.
*   Casual quiz game enthusiasts.

## 4. Scope

### 4.1. In Scope (MVP Features):

*   **`F-AUTH-01`**: User Authentication (Email/Password):
    *   Sign Up screen with email and password fields.
    *   Login screen with email and password fields.
    *   Basic input validation (e.g., email format, password length).
    *   Secure storage of credentials via Firebase Authentication.
    *   Creation of a corresponding user profile document in Firestore (`users` collection) upon signup.
    *   Logout functionality.
    *   Automatic redirection based on authentication state.
    *   *Enhancement:* Send email verification link upon signup.
    *   *Enhancement:* Display email verification status after login.
*   **`F-TOPIC-01`**: Topic Selection:
    *   Display a list of available quiz topics fetched from Firestore (`topics` collection).
    *   Allow users to select a topic to initiate matchmaking.
*   **`F-MATCH-01`**: Simple Matchmaking:
    *   On topic selection, add the user to a `matchmaking_pool` in Firestore for that topic.
    *   Display a "Waiting for opponent..." indicator.
    *   Client-side logic to query the pool for another waiting user on the same topic.
    *   Use Firestore transaction to create a `games` document and update both users' `currentMatchId` upon finding a match.
    *   Remove matched users from the `matchmaking_pool`.
    *   Automatic navigation to the Game Screen upon successful match.
    *   Basic handling if no match is found after a timeout (e.g., prompt user to try again - no complex retry logic).
*   **`F-GAME-01`**: Real-time Quiz Gameplay:
    *   Fetch game data (player info, question IDs) from the specific `games` document.
    *   Fetch actual question data based on IDs from the `questions` collection.
    *   Display one multiple-choice question at a time.
    *   Display options for the current question.
    *   Display a countdown timer per question.
    *   Allow the user to select one answer option.
    *   Submit the selected answer (index), time taken, and correctness to Firestore, updating the user's score and answer map within the `games` document.
    *   Listen to real-time updates on the `games` document via Firestore streams.
    *   Display both players' scores, updating in real-time.
    *   Visually indicate when the opponent has submitted their answer for the current question (e.g., a simple checkmark or greyed-out state).
    *   Handle question timer expiry (treat as incorrect/zero points, submit automatically).
    *   Advance to the next question only when both players have answered or timed out (Player 1 responsible for triggering Firestore update).
    *   Transition to the Results screen after the final question.
*   **`F-RESULT-01`**: Results Screen:
    *   Display the final scores for both players.
    *   Clearly indicate the winner, loser, or if it was a draw.
    *   Provide an option to navigate back to the Topic Selection screen.

### 4.2. Out of Scope (for MVP):

*   Social Login (Google, Facebook, etc.)
*   User Profiles (Avatars, detailed stats, edit profile)
*   Leaderboards (Global, Topic-specific)
*   Friend System (Adding friends, challenging friends)
*   In-Game Chat
*   Different Game Modes (e.g., solo play, tournaments)
*   Rematching the same opponent
*   Push Notifications
*   Advertisements or Monetization
*   Advanced anti-cheating mechanisms
*   Offline Mode or Caching
*   Password Reset UI/Flow
*   Detailed animations or visual effects
*   Sound Effects
*   Settings Screen
*   Analytics Integration (can be added late in MVP if time permits)

## 5. Functional Requirements

(Detailed breakdown covered by the features listed in "In Scope" section 4.1)

## 6. Non-Functional Requirements

*   **`NFR-PERF-01`**: UI Performance: App navigation and transitions should feel smooth on target devices (specify target OS versions/device classes if known).
*   **`NFR-PERF-02`**: Real-time Latency: Game state updates (score changes, opponent answer indication) should ideally reflect in the UI within 1-2 seconds of the event occurring in Firestore under normal network conditions.
*   **`NFR-SEC-01`**: Data Security: Implement Firestore Security Rules to prevent unauthorized read/write access, ensure users can only update their own game data during an active game, and protect user information. Player 1's designated role in advancing questions must be enforced.
*   **`NFR-USA-01`**: Usability: The UI should be intuitive and follow standard mobile platform conventions (Material Design). User flow from login to results should be clear. Provide visual feedback for user actions (taps, loading states, errors).
*   **`NFR-MAIN-01`**: Maintainability: Code should adhere to Flutter best practices, utilize the agreed-upon architecture (Feature-first, Repositories, Cubits), be reasonably commented, and include unit tests for critical logic (Cubits, Repositories).
*   **`NFR-REL-01`**: Reliability: The application should handle common errors (network disconnectivity, Firestore errors) gracefully, informing the user when necessary without crashing.

## 7. Data Model

Referencing the Firestore structure defined previously (`users`, `topics`, `questions`, `matchmaking_pool`, `games`).

## 8. Design & UI/UX

*   Focus on functionality over aesthetics for the MVP.
*   Utilize standard Flutter Material widgets.
*   Ensure clear visual hierarchy and readability.
*   Basic wireframes or mockups may be created separately but are not strictly part of this PRD.

## 9. Release Criteria

*   All "In Scope" features (Section 4.1) are implemented and demonstrably functional.
*   Core gameplay loop is stable and tested end-to-end.
*   Firestore Security Rules are implemented and tested for core scenarios.
*   No critical or blocking bugs identified in core functionality.
*   Application successfully builds and runs on target platforms (iOS/Android).
*   Basic error handling is in place.

## 10. Future Considerations (Post-MVP)

*   Implement features listed in "Out of Scope" (Section 4.2) based on feedback and priority.
*   Improve matchmaking algorithm (e.g., skill-based).
*   Add more robust error handling and connection management.
*   Introduce analytics for user behavior analysis.
*   Refine UI/UX and add visual polish/animations.
*   Optimize Firestore costs and performance.
*   Consider Cloud Functions for more complex backend logic.

## Development Roadmap (Phased Approach)

Estimates are rough (S=Small, M=Medium, L=Large).

### Phase 0: Foundation & Setup (S)

*   Task 0.1: Initialize Flutter Project & Git Repository. [DONE]
*   Task 0.2: Setup Firebase Project (Auth, Firestore). [DONE]
*   Task 0.3: Integrate Firebase SDKs into Flutter App. [DONE]
*   Task 0.4: Define Base Project Structure (Feature-first: core, features/auth, etc.). [DONE]
*   Task 0.5: Setup Dependency Injection (flutter_bloc, RepositoryProvider, BlocProvider). [DONE - Package Added]
*   Task 0.6: Define Core App Navigation Shell. [DONE - Basic Structure]

### Phase 1: Authentication (M)

*   Task 1.1: Implement AuthRepository (interface with FirebaseAuth). [DONE]
*   Task 1.2: Implement AuthCubit (manage login/signup state, interact with Repository). [DONE]
*   Task 1.3: Build UI Screens (Login, Signup). [DONE]
*   Task 1.4: Implement form validation. [DONE]
*   Task 1.5: Integrate Cubit with UI for state changes and actions. [DONE]
*   Task 1.6: Implement user creation in `users` collection on signup. [DONE - In AuthRepositoryImpl]
*   Task 1.7: Implement auth state listener for routing (App level). [DONE]
*   Task 1.8: Implement Logout functionality. [DONE - In HomeScreen]
*   *Enhancement:* Send email verification on signup. [DONE - In AuthRepositoryImpl]
*   *Enhancement:* Display verification status on Home Screen. [DONE - In HomeScreen]

### Phase 2: Topics & Basic Data (S-M)

*   Task 2.1: Manually Seed `topics` and `questions` data in Firestore.
*   Task 2.2: Implement TopicRepository (fetch topics).
*   Task 2.3: Implement QuestionRepository (fetch questions by ID - needed later).
*   Task 2.4: Implement TopicSelectionCubit.
*   Task 2.5: Build Topic Selection UI (List/Grid on Home Screen).
*   Task 2.6: Connect UI to Cubit to display topics.

### Phase 3: Matchmaking (M-L)

*   Task 3.1: Implement MatchmakingRepository (write to pool, query pool, perform match transaction, update users).
*   Task 3.2: Implement MatchmakingCubit (handle entering pool, waiting state, success/failure).
*   Task 3.3: Update Topic Selection UI: Trigger matchmaking on tap.
*   Task 3.4: Build "Waiting for Opponent" UI state/widget.
*   Task 3.5: Implement listener on users doc (`currentMatchId`) to detect match success.
*   Task 3.6: Setup navigation to Game Screen (placeholder initially).
*   Task 3.7: Implement basic timeout handling (client-side).

### Phase 4: Game Screen Foundation & State (M)

*   Task 4.1: Implement GameRepository (get `game` stream snapshots(), potentially game creation logic if not fully in Matchmaking repo).
*   Task 4.2: Define Game, Player, Answer data models/entities.
*   Task 4.3: Implement GameCubit (subscribe to game stream, manage game state).
*   Task 4.4: Build basic Game Screen UI structure.
*   Task 4.5: Implement logic in GameCubit to fetch initial game state and related questions (using QuestionRepository).
*   Task 4.6: Connect Game Screen UI to GameCubit to display basic info (players, initial state).

### Phase 5: Core Gameplay Loop & Real-time Sync (L)

*   Task 5.1: Implement Question & Options display widget in Game Screen.
*   Task 5.2: Implement Question Timer UI and logic (driven by GameCubit state).
*   Task 5.3: Implement answer selection UI interaction.
*   Task 5.4: Add `submitAnswer` method to GameRepository (update game doc in Firestore).
*   Task 5.5: Update GameCubit to handle answer submission, calculate score/time, call Repository.
*   Task 5.6: Update Game Screen UI to react to real-time score updates from GameCubit state.
*   Task 5.7: Implement UI indication for opponent's answer status.
*   Task 5.8: Add question advancement logic to GameRepository (update index, reset ready flags - called by Player 1).
*   Task 5.9: Implement logic in GameCubit (for Player 1) to check readiness and trigger question advancement via Repository.
*   Task 5.10: Handle game end detection in GameCubit (based on `currentQuestionIndex` vs `questionIds.length`).

### Phase 6: Results Screen (S)

*   Task 6.1: Build Results Screen UI.
*   Task 6.2: Implement navigation from Game Screen to Results Screen (triggered by GameCubit).
*   Task 6.3: Display final scores and winner determination on Results Screen (using final game state).
*   Task 6.4: Implement "Play Again" / "Home" navigation buttons.
*   Task 6.5: (Optional) Implement cleanup logic (e.g., nullify `currentMatchId`).

### Phase 7: Security, Polish & Testing (M-L)

*   Task 7.1: Write and Deploy Firestore Security Rules for all collections (`users`, `topics`, `questions`, `matchmaking_pool`, `games`).
*   Task 7.2: Test Security Rules thoroughly.
*   Task 7.3: Implement comprehensive Error Handling UI (Snackbars, dialogs) based on Cubit error states.
*   Task 7.4: Write Unit Tests for Cubits and Repositories.
*   Task 7.5: Perform Widget testing for key UI components.
*   Task 7.6: Conduct Manual End-to-End Testing of the entire user flow.
*   Task 7.7: Basic UI polish and consistency check.
*   Task 7.8: Setup build configurations for deployment (iOS/Android).
*   Task 7.9: (Optional) Setup basic analytics or crash reporting. 