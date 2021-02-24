package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/gha-workflow/src/gha"
	"github.com/gha-workflow/src/utils"
	"github.com/google/go-github/v33/github"
	"github.com/tidwall/gjson"
	"golang.org/x/oauth2"
)

type RepoStatus struct {
	Repo            string   `json:"repo"`
	Uses            []string `json:"uses"`
	Runs            []string `json:"runs"`
	ServiceImages   []string `json:"serviceImages"`
	ContainerImages []string `json:"containerImages"`
}

func getRepoStatus() []RepoStatus {
	token := ""
	ctx := context.Background()
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: token},
	)
	tc := oauth2.NewClient(ctx, ts)
	client := github.NewClient(tc)

	// get list of repositories
	orgName := "anzx"
	repositories, err := gha.FetchRepositoriesForOrg("anzx", client)
	if err != nil {
		log.Println(err)

	}
	//get workflows for each repostiories
	var repoStatusList []RepoStatus
	for _, r := range repositories {
		// create a instance of repoStatus struct
		rs := RepoStatus{Repo: r.GetName()}
		var uses []string
		var runs []string
		var containerImages []string
		var serviceImages []string
		ws, err := gha.FetchWorkflowForRepo(r.GetName(), "anzx", client)
		if err != nil {
			log.Println(err)
			continue
		}
		// if no workflows for a gha, skip this repo
		if ws.GetTotalCount() == 0 {
			continue
		}
		// Get workflow path for each workflow files
		for _, w := range ws.Workflows {
			path := w.GetPath()
			// call get repo content api based on this path
			content, err := gha.FetchRepoFileContent(orgName, r.GetName(), path, client)
			if err != nil {
				log.Println(err)
				continue
			}
			// get the content
			c, err := content.GetContent()
			if err != nil {
				log.Println(err)
				continue
			}

			jsonValue, err := utils.ConvertYamlTojson([]byte(c))
			if err != nil {
				log.Println(err)
				continue
			}

			var singleUses []string
			var singleRuns []string
			var singleContainerImages []string
			var singleContainerServiceImages []string

			steps := gjson.Get(*jsonValue, "jobs.*.steps")
			containerImage := gjson.Get(*jsonValue, "jobs.*.container.image").String()
			singleContainerImages = append(singleContainerImages, containerImage)
			serviceImage := gjson.Get(*jsonValue, "jobs.*.services.*.image").String()
			singleContainerServiceImages = append(singleContainerServiceImages, serviceImage)

			steps.ForEach(func(key, value gjson.Result) bool {
				singleUses = append(singleUses, gjson.Get(value.Raw, "uses").String())
				singleRuns = append(singleRuns, gjson.Get(value.Raw, "run").String())
				return true
			})

			runs = append(runs, singleRuns...)
			uses = append(uses, singleUses...)

			containerImages = append(containerImages, singleContainerImages...)
			serviceImages = append(serviceImages, singleContainerServiceImages...)

		}

		rs.Runs = runs
		rs.Uses = uses
		rs.ContainerImages = containerImages
		rs.ServiceImages = serviceImages
		repoStatusList = append(repoStatusList, rs)
	}
	return repoStatusList
}

func main() {
	jsonData, err := json.Marshal(getRepoStatus())
	if err != nil {
		log.Println(err)
	}
	fmt.Printf("%v", string(jsonData))

	utils.CreateFile("result.yaml", string(jsonData))
}
