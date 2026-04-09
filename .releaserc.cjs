module.exports = {
  branches: ["main"],
  tagFormat: "v${version}",
  plugins: [
    // Analyzes commit messages to determine the release type (patch, minor, major).
    // releaseRules explicitly prevent non-feature/fix types from triggering a release.
    [
      "@semantic-release/commit-analyzer",
      {
        preset: "conventionalcommits",
        releaseRules: [
          { type: "docs", release: false },
          { type: "chore", release: false },
          { type: "refactor", release: false },
          { type: "test", release: false },
          { type: "style", release: false },
          { type: "ci", release: false },
          { type: "build", release: false },
        ],
      },
    ],

    // Generates markdown release notes from the analyzed commits.
    "@semantic-release/release-notes-generator",

    // Prepends the generated release notes to CHANGELOG.md.
    [
      "@semantic-release/changelog",
      {
        changelogFile: "CHANGELOG.md",
      },
    ],

    // Bumps the version in package.json and package-lock.json.
    // npmPublish is false because this is a skill repo, not an npm package.
    [
      "@semantic-release/npm",
      {
        npmPublish: false,
      },
    ],

    // Creates a GitHub Release with release notes.
    "@semantic-release/github",

    // Commits the updated files and creates a git tag.
    // The [skip ci] in the message prevents the release commit from re-triggering CI.
    [
      "@semantic-release/git",
      {
        assets: ["CHANGELOG.md", "package.json", "package-lock.json"],
        message:
          "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}",
      },
    ],
  ],
};
