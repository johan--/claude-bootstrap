# Contributing to Claude Bootstrap

Thanks for your interest in contributing! This project aims to make AI-assisted development more reliable and consistent.

## Philosophy

Before contributing, understand the core philosophy:

1. **Complexity is the enemy** - Every line of code is a liability
2. **Measurable constraints** - Prefer specific numbers (20 lines/fn) over vague guidance
3. **Security is non-negotiable** - All projects must pass security checks
4. **AI-first thinking** - LLMs for logic, code for plumbing
5. **Spec-driven** - Define before you build

## How to Contribute

### Adding a New Skill

1. Create a new file in `skills/` following the naming pattern: `[topic].md`
2. Start with the header and dependency line:
   ```markdown
   # [Topic] Skill

   *Load with: base.md + [other dependencies]*
   ```
3. Include these sections:
   - Core principles
   - Project structure (if applicable)
   - Patterns with code examples
   - Anti-patterns list
4. Add measurable constraints where possible
5. Update `README.md` to include the new skill

### Improving Existing Skills

1. Keep changes focused on one improvement
2. Maintain the existing structure
3. Ensure examples are correct and tested
4. Update version comments if significant

### Updating the Initialize Command

1. Test changes locally before submitting
2. Ensure idempotency - running twice shouldn't break anything
3. Preserve user customizations (never overwrite `_project_specs/`)

## Skill Guidelines

### Do

- Use specific, measurable constraints
- Provide working code examples
- Include anti-patterns with explanations
- Keep skills focused on one topic
- Reference other skills when building on them

### Don't

- Use vague guidance ("write clean code")
- Include time estimates
- Add features beyond what's needed
- Break existing projects when run as update

## Testing Your Changes

```bash
# Install your changes
./install.sh

# Test on a new project
mkdir test-project && cd test-project
claude
> /initialize-project

# Test on an existing project
cd existing-project
claude
> /initialize-project
# Should update skills without breaking existing config
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-skill`)
3. Make your changes
4. Test locally
5. Submit PR with clear description of changes

## Code of Conduct

- Be respectful and constructive
- Focus on technical merit
- Welcome newcomers
- Share knowledge freely

## Questions?

Open an issue for:
- Bug reports
- Feature requests
- Clarification on philosophy
- Help with implementation
