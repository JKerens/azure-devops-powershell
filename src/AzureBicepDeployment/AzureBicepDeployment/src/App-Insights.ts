import {
    TelemetryClient,
    DistributedTracingModes,
    setup,
    defaultClient
} from "applicationinsights";
import tl = require("azure-pipelines-task-lib/task");

const instrumentationKey = "<add-your-key-here>";

const initializeAppInsights = () => {
    setup(instrumentationKey)
        .setAutoDependencyCorrelation(true)
        .setAutoCollectRequests(true)
        .setAutoCollectPerformance(true, true)
        .setAutoCollectExceptions(true)
        .setAutoCollectDependencies(true)
        .setAutoCollectConsole(true)
        .setUseDiskRetryCaching(true)
        .setSendLiveMetrics(false)
        .setDistributedTracingMode(DistributedTracingModes.AI)
        .start();

    let client: TelemetryClient = defaultClient;

    return client;
};

let telemetryClient: TelemetryClient = initializeAppInsights();

export function sendTraceEvent(): void {
    try {
        telemetryClient.trackEvent({
            name: "Extension - Azure Bicep Deployment",
            properties: {
                agentVersion: tl.getVariable("<add-something-to-track>")
            }
        });
    } catch (e) {
        console.error(e)
    } finally {
        telemetryClient.flush();
    }
}