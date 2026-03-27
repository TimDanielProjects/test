using System;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Extensions.Workflows;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Function
{

    /// <summary>  
    /// Represents the Function flow invoked function.  
    /// </summary>  
    public class Function
    {
        private readonly ILogger<Function> _logger;

        public Function(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<Function>();
        }

        /// <summary>
        /// Azure Function entry point.
        /// </summary>
        /// <param name="input">The input string from the workflow trigger.</param>
        /// <returns>A task that represents the asynchronous operation. The task result contains the output string.</returns>
        [Function("Function")]
        public async Task<string> Run([WorkflowActionTrigger] string input)
        {
            try
            {
                _logger.LogInformation("Function started");

                //**********************************************************************************
                //The function logic goes here


                // Process the input
                var output = input;

                // Return the result
                return await Task.FromResult("Your input was: " + output + ".");


                //**********************************************************************************
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred in Function");
                throw;
            }
        }
    }
}
