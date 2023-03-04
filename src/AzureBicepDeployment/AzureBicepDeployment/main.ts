import path = require("path");
import tl = require("azure-pipelines-task-lib/task");
import fs = require("fs");
import { IScript, ScriptTypeFactory } from "./src/ScriptFactory";
import { ToolRunner } from 'azure-pipelines-task-lib/toolrunner';
import { sendTraceEvent } from "./src/App-Insights";

const FAIL_ON_STDERR: string = "FAIL_ON_STDERR";

export class runnerTask {

    public static async run(): Promise<void> {
        var toolExecutionError = null;
        var exitCode: number = 0;
        try {
            // Uncomment for logging if you need it
            // Make sure to fill out the missing settings 
            // in App-Insights.ts before using
            // sendTraceEvent();
            let scriptType: IScript = ScriptTypeFactory.getScriptType();
            let tool: ToolRunner = await scriptType.getTool();

            // determines whether output to stderr will fail a task.
            // some tools write progress and other warnings to stderr.  scripts can also redirect.
            let failOnStdErr: boolean = true;

            let aggregatedErrorLines: string[] = [];

            exitCode = await tool.exec({
                failOnStdErr: false,
                ignoreReturnCode: true
            });
    
            if (failOnStdErr && aggregatedErrorLines.length > 0) {
                let error = FAIL_ON_STDERR;
                tl.error(aggregatedErrorLines.join("\n"));
                throw error;
            }
        }
        catch (err) {
            toolExecutionError = err;
            if (err.stderr) {
                toolExecutionError = err.stderr;
            }
        }
        finally {
            //set the task result to either succeeded or failed based on error was thrown or not
            // These messages are found in the task.json file at the bottom
            if(toolExecutionError === FAIL_ON_STDERR) {
                tl.setResult(tl.TaskResult.Failed, tl.loc("ScriptFailedStdErr"));
            } else if (toolExecutionError) {
                tl.setResult(tl.TaskResult.Failed, tl.loc("ScriptFailed", toolExecutionError));
            } else if (exitCode != 0){
                tl.setResult(tl.TaskResult.Failed, tl.loc("ScriptFailedWithExitCode", exitCode));
            }
            else {
                tl.setResult(tl.TaskResult.Succeeded, tl.loc("ScriptReturnCode", 0));
            }
        }
    }

}
tl.setResourcePath(path.join(__dirname, "task.json"));
runnerTask.run();