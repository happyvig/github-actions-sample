const core = require('@actions/core');
const github = require('@actions/github');

async function run() {

  const repoToken = core.getInput('repo-token');
  const pattern = core.getInput('pattern');
  const regex = new RegExp(pattern);
  const title =
    github.context.payload &&
    github.context.payload.pull_request &&
    github.context.payload.pull_request.title;
  
  const {
    payload: { pull_request: pullRequest, repository }
  } = github.context;
  const { number: issueNumber } = pullRequest;
  const { full_name: repoFullName } = repository;
  const [owner, repo] = repoFullName.split("/");

  const octokit = new github.GitHub(repoToken);

  core.info(title);
  const isValid = regex.test(title)
  if (!isValid) {
    core.setOutput("pr-title-format", "invalid");

    let response = await octokit.issues.createLabel({ 
      owner, 
      repo, 
      name: 'check-pr-title-format', 
      color: '#ff0000', 
      description: 'Label to identify whether the PR title is in the required format' 
    });

    console.log('Label created !!!!');
    console.log(response)
    console.log(`Added the new label to the issue #{issueNumber}`);
    if(response) {
      await octokit.issues.addLabels({ 
        owner, 
        repo, 
        issueNumber, 
        labels: ['check-pr-title-format']
      });
    }

    core.setFailed(
      `Pull request title "${title}" does not match regex pattern "${pattern}".`,
    );

  } else {
    core.setOutput("pr-title-format", "valid");
    console.log(`Removing the 'check-pr-title-format' label from the issue #{issueNumber}`);
    await octokit.issues.removeLabel({ 
      owner, 
      repo, 
      issueNumber, 
      name: 'check-pr-title-format'
    });
  }
}

run()