using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace FunctionApp
{
    public class HttpTriggerSimple
    {
        [Function("read-secret")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req,
            FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("FunctionApp.HttpTriggerSimple");
            logger.LogInformation("Starting secret read");

            if (String.IsNullOrEmpty(req.Query["name"]))
            {
                return new OkObjectResult("name is required as query param");
            }

            string keyVaultName = Environment.GetEnvironmentVariable("KEY_VAULT_NAME");
            var kvUri = "https://" + keyVaultName + ".vault.azure.net";

            try
            {
                var client = new SecretClient(new Uri(kvUri), new DefaultAzureCredential());
                KeyVaultSecret secret = await client.GetSecretAsync(req.Query["name"]);
                logger.LogInformation(secret.Value);
                return new OkObjectResult(secret.Value);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to read secret.");
                return new OkObjectResult($"Secret was not found");
            }


        }

    }
}
