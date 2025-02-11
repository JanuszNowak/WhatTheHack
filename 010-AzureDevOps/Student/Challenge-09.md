# Challenge 09 - Azure Pipelines: OSS Scanning with WhiteSource Bolt

[< Previous Challenge](./Challenge-08.md) - **[Home](../README.md)**

## Introduction

Azure DevOps is a very open platform. You can not only swap out major components, for example if your company has an investment in Jenkins or Octopus Deploy can use them instead of Azure Pipelines and still take advantage of other Azure DevOps services like Azure Repos, Azure Boards, etc.

You can also integrate 3rd party tools, into your Azure DevOps workflow. In this exercise we are going to add support for WhiteSource Bolt. It is a Free developer tool for finding and fixing open source vulnerabilities. Find out more about it by reviewing the following article.

- [WhiteSource Bolt For Azure DevOps](https://bolt.whitesourcesoftware.com/azure/)

## Description

In this challenge we will deploy WhiteSource Bolt to scan our source code to see if we have any issues with our OSS dependencies.

- Follow the directions in the above article to install WhiteSource Bolt
- Add a task to your Pull Request Build to run WhiteSource Bolt

## Success Criteria

1. Run your build again, what vulnerabilities were found?