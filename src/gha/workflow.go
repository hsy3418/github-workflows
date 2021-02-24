package gha

import (
	"context"

	"github.com/google/go-github/v33/github"
)

func FetchWorkflowForRepo(repo string, owner string, client *github.Client) (*github.Workflows, error) {
	workflows, _, err := client.Actions.ListWorkflows(context.Background(), owner, repo, nil)
	return workflows, err
}
