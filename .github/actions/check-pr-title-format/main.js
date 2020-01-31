const core = require('@actions/core');
const github = require('@actions/github');

function run() {
  const pattern = core.getInput('pattern');
  const regex = new RegExp(pattern);
  const title =
    github.context.payload &&
    github.context.payload.pull_request &&
    github.context.payload.pull_request.title;
  
  core.info(title);
  const isValid = regex.test(title)
  if (!isValid) {
    core.setOutput("pr-title-format", "invalid");
    core.setFailed(
      `Pull request title "${title}" does not match regex pattern "${pattern}".`,
    )
  } else {
    core.setOutput("pr-title-format", "valid");
  }
}

run()