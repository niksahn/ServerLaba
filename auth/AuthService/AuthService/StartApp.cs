using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using MongoDB.Driver;
using Microsoft.OpenApi.Models;
using Prometheus;


namespace AuthService
{
    public class Startup
    {
        private readonly IConfiguration _configuration;

        public Startup(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddSingleton<IMongoClient, MongoClient>(sp =>
                new MongoClient(_configuration.GetConnectionString("MongoDbConnection")));

            services.AddSingleton(sp => new ApiService());

            services.AddControllers();
            // Health checks (опционально, полезно для мониторинга)
            services.AddHealthChecks();

            // Добавление Swagger
            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo
                {
                    Title = "Auth Service API",
                    Version = "v1"
                });
            });
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();

                // Включение средст Swagger только для разработки
                app.UseSwagger();
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Auth Service API V1");
                    c.RoutePrefix = string.Empty; // Устанавливает Swagger UI доступным по корневому URL
                });
            }

            app.UseRouting();
            app.UseHttpMetrics();


            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();

                // Endpoint метрик для Prometheus
                endpoints.MapMetrics("/metrics");

                // Health endpoint (опционально)
                endpoints.MapHealthChecks("/health");
            });
        }
    }
}