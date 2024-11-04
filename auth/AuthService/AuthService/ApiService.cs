using System.Net.Http.Headers;

public class ApiService
{
        private readonly HttpClient _httpClient;

        public ApiService()
        {
            _httpClient = new HttpClient();
            _httpClient.DefaultRequestHeaders.Accept.Clear();
            _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        }
    
   public async Task<T?> PostResourceAsync<T,B>(string endpoint, B body)
    {
        try
        {
            HttpResponseMessage resp = await _httpClient.PostAsJsonAsync<B>(endpoint, body);
            T? data = await resp.Content.ReadFromJsonAsync<T?>();
            return data;
        }
        catch (Exception e)
        {
            // Обработка ошибок
            Console.WriteLine($"Request error: {e.Message}");
            return default(T);
        }
    }
}


