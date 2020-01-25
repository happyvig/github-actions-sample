const core = require('@actions/core');
const github = require('@actions/github');

async function run() {
  try{
    // This should be a token with access to your repository scoped in as a secret.
    // The YML workflow will need to set myToken with the GitHub Secret Token
    // myToken: ${{ secrets.GITHUB_TOKEN }}
    // https://help.github.com/en/actions/automating-your-workflow-with-github-actions/authenticating-with-the-github_token#about-the-github_token-secret
   
    const repoToken = core.getInput('repo-token');
    const message = core.getInput('message');

    console.log(`Message: ${message}`);

    const {
      payload: { pull_request: pullRequest, repository }
    } = github.context;

    // if (!pullRequest) {
    //   core.error("this action only works on pull_request events");
    //   core.setOutput("comment-created", "false");
    //   return;
    // }

    const { number: issueNumber } = pullRequest;
    const { full_name: repoFullName } = repository;
    const [owner, repo] = repoFullName.split("/");

    const octokit = new github.GitHub(repoToken);

    console.log(`Creating commit.....`);
    console.log(`Owner: ${owner}`);
    console.log(`Repo: ${repo}`);
    console.log(`IssueNumber: ${issueNumber}`);
    console.log(`Message: ${message}`);

    await octokit.issues.createComment({
        owner,
        repo,
        issue_number: issueNumber,
        body: message
    });

    console.log(`Commit created !!`);

    core.setOutput("comment-created", "true");
  } 
  catch(error) {
    core.setFailed(error.message);
  }
}

run();
