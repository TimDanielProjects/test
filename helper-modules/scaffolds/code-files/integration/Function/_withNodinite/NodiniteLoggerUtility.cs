using Newtonsoft.Json;
using Serilog.Core.Enrichers;
using Serilog.Events;
using System;

namespace Function
{
    /// <summary>
    /// Utility class for logging messages to Nodinite using Serilog.
    /// </summary>
    public class NodiniteLoggerUtility
    {
        private readonly Serilog.ILogger _logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="NodiniteLoggerUtility"/> class.
        /// </summary>
        /// <param name="logger">The Serilog logger instance.</param>
        public NodiniteLoggerUtility(Serilog.ILogger logger)
        {
            _logger = logger;
        }

        /// <summary>
        /// Logs an informational message with an optional payload, message type, and correlation ID.
        /// </summary>
        public void LogInformation(string workflowName, string correlationId, string logMessage = "Hello from Function",  object payload = null, string messageType = "Information")
        {
            Log(workflowName, correlationId, logMessage, payload, messageType,  LogEventLevel.Information);
        }

        /// <summary>
        /// Logs an error message with an optional payload, message type, and correlation ID.
        /// </summary>
        public void LogError(string workflowName, string correlationId, string logMessage = "An error occurred",  object payload = null, string messageType = "Error")
        {
            Log(workflowName, correlationId, logMessage, payload, messageType, LogEventLevel.Error);
        }

        /// <summary>
        /// Logs a warning message with an optional payload, message type, and correlation ID.
        /// </summary>
        public void LogWarning(string workflowName, string correlationId, string logMessage = "A warning occurred",  object payload = null, string messageType = "Warning")
        {
            Log(workflowName, correlationId, logMessage, payload, messageType, LogEventLevel.Warning);
        }

        private void Log(string workflowName, string correlationId, string logMessage, object payload, string messageType, LogEventLevel logEventLevel)
        {
            try
            {
                string serializedPayload = payload != null ? JsonConvert.SerializeObject(payload) : null;

                var loggerContext = _logger.ForContext(new PropertyEnricher("ApplicationInterchangeId", correlationId))
                                           .ForContext(new PropertyEnricher("OriginalMessageType", messageType))
                                           .ForContext(new PropertyEnricher("EndPointName", workflowName));

                if (serializedPayload != null)
                {
                    loggerContext = loggerContext.ForContext(new PropertyEnricher("Body", serializedPayload));
                }

                string color = logEventLevel switch
                {
                    LogEventLevel.Information => "Green",
                    LogEventLevel.Error => "Red",
                    LogEventLevel.Warning => "Yellow",
                    _ => "White"
                };

                loggerContext = loggerContext.ForContext("Color", color);

                loggerContext.Write(logEventLevel, logMessage);
            }
            catch (Exception ex)
            {
                _logger.Error(ex, "An error occurred while initializing the Nodinite logger.");
                throw;
            }
        }
    }
}
