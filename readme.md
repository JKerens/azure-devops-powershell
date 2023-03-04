# Using Azure DevOps Task Extension with Node10 and PowerShell Core

## Description

This project demonstrates how to use an Azure DevOps task extension using Node10 as the runner, allowing it to work on both Windows and Linux. Additionally, it shows how to quickly switch back to using PowerShell Core, without having to write a lot of TypeScript. Lastly, I show a couple key concepts like consuming a service principle.

## Disclaimer

Most of this code was just me looking at how Azure Cli and Azure PowerShell tasks managed to run PowerShell scripts just fine despite the Windows PowerShell runner being sunset in pipeline tasks. I'm also not amazing at Typescript so use with caution.

## Further Reading

- Authoring Tasks Tutorial - [Link](https://learn.microsoft.com/azure/devops/extend/develop/add-build-task?view=azure-devops)
- How do the other tasks do it? - [Link](https://github.com/microsoft/azure-pipelines-tasks/tree/master/Tasks)
