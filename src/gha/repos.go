package gha

import (
	"context"

	"github.com/google/go-github/v33/github"
)

func FetchRepoFileContent(owner string, repoName string, path string, client *github.Client) (*github.RepositoryContent, error) {
	fileContent, _, _, err := client.Repositories.GetContents(context.Background(), owner, repoName, path, nil)
	return fileContent, err
}

func FetchRepositoriesForAUser(username string, client *github.Client) ([]*github.Repository, error) {

	orgs, _, err := client.Repositories.List(context.Background(), username, nil)
	return orgs, err
}

func FetchRepositoriesForOrg(org string, client *github.Client) ([]*github.Repository, error) {
	opt := &github.RepositoryListByOrgOptions{
		ListOptions: github.ListOptions{PerPage: 10},
	}
	var allRepos []*github.Repository
	for {
		repos, resp, err := client.Repositories.ListByOrg(context.Background(), org, opt)
		if err != nil {
			return nil, err
		}
		allRepos = append(allRepos, repos...)
		if resp.NextPage == 0 {
			break
		}
		opt.Page = resp.NextPage
	}
	return allRepos, nil
}
