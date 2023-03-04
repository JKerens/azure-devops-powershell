import tl = require("azure-pipelines-task-lib/task");
import os = require("os");
import path = require("path");
import { IExecSyncResult } from 'azure-pipelines-task-lib/toolrunner';
import fs = require("fs");

// So I can have compile time feedback on typos for getInputs 
export function nameof<T>(key: keyof T, instance?: T): keyof T {
    return key;
}

export interface Inputs {
    serviceName: string;
    bicepFile: string;
    parametersFile: string;
    location: string;
    mode : string;
}

export function getInputs() : Inputs {

    return {
        serviceName: tl.getInput(nameof<Inputs>('serviceName'),/*required*/true),
        bicepFile: tl.getPathInput(nameof<Inputs>('bicepFile'), /*required*/true, /*check*/true),
        parametersFile: tl.getPathInput(nameof<Inputs>('parametersFile'), /*check*/true),
        location: tl.getInput(nameof<Inputs>('location'), /*required*/true),
        mode: tl.getInput(nameof<Inputs>('mode'), /*required*/true)
    }
}

export class Utility {

    public static async getPowerShellScriptPath(): Promise<string> {
        let scriptPath: string = path.join(__dirname, 'Run.ps1');
        return scriptPath;
    }

    public static throwIfError(resultOfToolExecution: IExecSyncResult, errormsg?: string): void {
        if (resultOfToolExecution.code != 0) {
            tl.error("Error Code: [" + resultOfToolExecution.code + "]");
            if (errormsg) {
                tl.error("Error: " + errormsg);
            }
            throw resultOfToolExecution;
        }
    }


    public static checkIfFileExists(filePath: string, fileExtensions: string[]): boolean {
        let matchingFiles: string[] = fileExtensions.filter((fileExtension: string) => {
            if (tl.stats(filePath).isFile() && filePath.toUpperCase().match(new RegExp(`\.${fileExtension.toUpperCase()}$`))) {
                return true;
            }
        });
        if (matchingFiles.length > 0) {
            return true;
        }
        return false;
    }

    public static async deleteFile(filePath: string): Promise<void> {
        if (fs.existsSync(filePath)) {
            try {
                //delete the publishsetting file created earlier
                fs.unlinkSync(filePath);
            }
            catch (err) {
                //error while deleting should not result in task failure
                console.error(err.toString());
            }
        }
    }
}
