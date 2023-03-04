import { Utility, getInputs, Inputs } from './Inputs';
import tl = require("azure-pipelines-task-lib/task");
import { ToolRunner } from 'azure-pipelines-task-lib/toolrunner';
import { AzureRMEndpoint } from 'azure-pipelines-tasks-azure-arm-rest-v2/azure-arm-endpoint';

export class ScriptTypeFactory {
    public static getScriptType(): IScript {  
        return new PowerShellCore();
    }
}

export interface IScript {

    getTool(): Promise<ToolRunner>;
}

// Just Trying to get over to PowerShell as quick as possible
export class PowerShellCore implements IScript {

    public async getTool(): Promise<ToolRunner> {
        let inputs: Inputs = getInputs();
        let endpointObject= await new AzureRMEndpoint(inputs.serviceName).getEndpoint();
        let scriptPath: string = await Utility.getPowerShellScriptPath();
        let endpoint: string = JSON.stringify(endpointObject);

        // You literally just relay the inputs over to PowerShell
        let tool: ToolRunner = tl.tool(tl.which('pwsh', true))
            .arg('-NoProfile')
            .arg('-NonInteractive')
            .arg('-ExecutionPolicy')
            .arg('Unrestricted')
            .arg('-File')
            .arg(scriptPath)
            .arg('-Endpoint')
            .arg(endpoint)
            .arg('-BicepFile')
            .arg(inputs.bicepFile)
            .arg('-ParametersFile')
            .arg(inputs.parametersFile)
            .arg('-Location')
            .arg(inputs.location)
            .arg('-Mode')
            .arg(inputs.mode);
        
        return tool;
    }
}
