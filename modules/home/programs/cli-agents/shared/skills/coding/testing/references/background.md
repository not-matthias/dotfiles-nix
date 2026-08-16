# Background and Further Reading

AI-written tests often become descriptions of current code rather than specifications of intended behavior. They pass because their assertion repeats the implementation's assumptions instead of challenging them.

> “The more your tests resemble the way your software is used, the more confidence they can give you.” — Kent C. Dodds

Mark Seemann describes this failure mode as tests used as ceremony rather than as an application of the scientific method. The linked MSR '26 study reports that agent-authored changes concentrate mocks more heavily than human-authored changes.

## Sources

- [Testing Implementation Details — Kent C. Dodds](https://kentcdodds.com/blog/testing-implementation-details)
- [Write Tests. Not Too Many. Mostly Integration. — Kent C. Dodds](https://kentcdodds.com/blog/write-tests)
- [How to Know What to Test — Kent C. Dodds](https://kentcdodds.com/blog/how-to-know-what-to-test)
- [Test Desiderata — Kent Beck](https://testdesiderata.com/)
- [Mocks Aren't Stubs — Martin Fowler](https://martinfowler.com/articles/mocksArentStubs.html)
- [AI-Generated Tests as Ceremony — Mark Seemann](https://blog.ploeh.dk/2026/01/26/ai-generated-tests-as-ceremony/)
- [Over-Mocked Tests Empirical Study (MSR '26)](https://arxiv.org/html/2602.00409v1)
- [TDD with AI Agents — QA Skills](https://qaskills.sh/blog/tdd-ai-agents-best-practices)
