# Contribution Guide

Thank you for your interest in contributing to ICTO v2! We welcome contributions from the community to help us improve and grow the platform. This guide provides all the information you need to get started.

## How to Contribute

We welcome contributions in various forms, including:

- **Bug Reports**: If you find a bug, please open an issue on our GitHub repository. Provide as much detail as possible, including steps to reproduce the issue.
- **Feature Requests**: If you have an idea for a new feature, open an issue to discuss it. We are always open to new ideas.
- **Code Contributions**: If you want to contribute code, please follow the process outlined below.
- **Documentation**: We are always looking to improve our documentation. If you see an area that can be improved, feel free to submit a pull request.

## Understanding the Codebase

Before you start contributing code, it is important to have a good understanding of the project's architecture. We recommend reading the following documents in this `documentation/` directory:

- **`README.md`**: For a high-level overview of the project.
- **`backend.md`**: To understand the Motoko backend architecture.
- **`frontend.md`**: To understand the Vue 3 frontend structure.
- **`development.md`**: For instructions on how to set up your local development environment.

## Code Contribution Workflow

1.  **Fork the Repository**: Start by forking the official ICTO v2 repository on GitHub.
2.  **Create a New Branch**: Create a new branch for your feature or bug fix.

    ```bash
    git checkout -b my-new-feature
    ```

3.  **Make Your Changes**: Make your changes to the codebase, following the code style and conventions described below.
4.  **Test Your Changes**: Ensure that your changes do not break any existing functionality. Run the relevant test scripts in the `scripts/` directory.
5.  **Submit a Pull Request**: Once you are happy with your changes, submit a pull request to the `main` branch of the official repository. Provide a clear description of the changes you have made.

## Code Style and Linting

- **Motoko**: Follow the standard Motoko formatting and style guidelines. Use the Motoko extension for Visual Studio Code to automatically format your code.
- **TypeScript/Vue**: We use ESLint and Prettier to enforce a consistent code style for the frontend. Before submitting a pull request, please run the linter and formatter:

  ```bash
  npm run lint
  npm run format
  ```

## Where to Start Contributing

If you are new to the project, here are some good places to start:

- **Good First Issues**: Look for issues tagged with `good first issue` on our GitHub repository. These are typically smaller, well-defined tasks that are a great way to get started.
- **Documentation**: Improving the documentation is a great way to contribute to the project and learn more about it at the same time.
- **Frontend UI**: There are always opportunities to improve the user interface and user experience. If you have skills in Vue and Tailwind CSS, this is a great place to contribute.

## Useful Links and Community Resources

- **GitHub Repository**: [https://github.com/ICTO-Labs/icto_v2](https://github.com/ICTO-Labs/icto_v2)
- **Internet Computer Documentation**: [https://internetcomputer.org/docs/current/developer-docs/](https://internetcomputer.org/docs/current/developer-docs/)
- **Motoko Programming Language Guide**: [https://internetcomputer.org/docs/current/motoko/main/motoko](https://internetcomputer.org/docs/current/motoko/main/motoko)
- **Vue 3 Documentation**: [https://vuejs.org/](https://vuejs.org/)
- **DFINITY Developer Forum**: [https://forum.dfinity.org/](https://forum.dfinity.org/)

We look forward to your contributions!
