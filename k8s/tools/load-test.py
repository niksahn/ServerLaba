#!/usr/bin/env python3
"""
Упрощенный скрипт для нагрузочного тестирования алгоритмов балансировки Nginx
Использование: python3 load-test.py <api-gateway-url> [algorithm] [duration] [concurrent-users]
"""

import sys
import time
import statistics
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests

class LoadTester:
    def __init__(self, api_gateway_url, algorithm, duration, concurrent_users):
        self.api_gateway_url = api_gateway_url.rstrip('/')
        self.algorithm = algorithm
        self.duration = int(duration)
        self.concurrent_users = int(concurrent_users)
        self.test_user = "123"
        self.test_password = "123"
        
        self.results = {
            'total_requests': 0,
            'successful_requests': 0,
            'failed_requests': 0,
            'response_times': [],
            'error_types': {},  # Типы ошибок (timeout, connection_error, etc.)
            'status_codes': {}  # Статус-коды ответов
        }
        
        # Авторизация один раз при инициализации
        self.access_token = self._user_authorization()
        
    def _user_authorization(self):
        """Получить токен авторизации"""
        try:
            auth_response = requests.post(
                f"{self.api_gateway_url}/auth",
                json={"username": self.test_user, "password": self.test_password},
                timeout=10
            )
            if auth_response.status_code == 200:
                return auth_response.json().get("accessToken")
            else:
                print(f"Предупреждение: авторизация вернула статус {auth_response.status_code}")
                return None
        except requests.exceptions.RequestException as e:
            print(f"Ошибка при авторизации: {e}")
            return None
        
    def make_request(self):
        """Выполнить один HTTP запрос GET /films с авторизацией"""
        url = f"{self.api_gateway_url}/films"
        
        start_time = time.time()
        try:
            headers = {'auth': f"Bearer {self.access_token}"}
            response = requests.get(url, headers=headers, timeout=10)
            elapsed_time = (time.time() - start_time) * 1000  # в миллисекундах
            
            return {
                'status_code': response.status_code,
                'response_time': elapsed_time,
                'success': response.status_code == 200,
                'error': None,
                'error_type': None
            }
        except requests.exceptions.Timeout as e:
            elapsed_time = (time.time() - start_time) * 1000
            return {
                'status_code': 0,
                'response_time': elapsed_time,
                'success': False,
                'error': str(e),
                'error_type': 'timeout'
            }
        except requests.exceptions.ConnectionError as e:
            elapsed_time = (time.time() - start_time) * 1000
            return {
                'status_code': 0,
                'response_time': elapsed_time,
                'success': False,
                'error': str(e),
                'error_type': 'connection_error'
            }
        except requests.exceptions.HTTPError as e:
            elapsed_time = (time.time() - start_time) * 1000
            return {
                'status_code': 0,
                'response_time': elapsed_time,
                'success': False,
                'error': str(e),
                'error_type': 'http_error'
            }
        except requests.exceptions.RequestException as e:
            elapsed_time = (time.time() - start_time) * 1000
            return {
                'status_code': 0,
                'response_time': elapsed_time,
                'success': False,
                'error': str(e),
                'error_type': 'other_error'
            }
    
    def worker(self, worker_id, end_time):
        """Воркер для выполнения запросов"""
        worker_results = {
            'requests': 0,
            'successful': 0,
            'failed': 0,
            'response_times': [],
            'error_types': {},
            'status_codes': {}
        }
        
        while time.time() < end_time:
            result = self.make_request()
            
            worker_results['requests'] += 1
            worker_results['response_times'].append(result['response_time'])
            
            # Собираем статистику по статус-кодам
            status = result['status_code']
            worker_results['status_codes'][status] = worker_results['status_codes'].get(status, 0) + 1
            
            if result['success']:
                worker_results['successful'] += 1
            else:
                worker_results['failed'] += 1
                # Собираем статистику по типам ошибок
                error_type = result.get('error_type', 'unknown')
                worker_results['error_types'][error_type] = worker_results['error_types'].get(error_type, 0) + 1
            
            time.sleep(0.1)  # Небольшая задержка между запросами
        
        return worker_id, worker_results
    
    def run(self):
        """Запустить нагрузочное тестирование"""
        if not self.access_token:
            print("ОШИБКА: Не удалось получить токен авторизации")
            return False
            
        print("=" * 60)
        print("Нагрузочное тестирование балансировщика")
        print("=" * 60)
        print(f"API Gateway URL: {self.api_gateway_url}")
        print(f"Алгоритм балансировки: {self.algorithm}")
        print(f"Длительность теста: {self.duration} секунд")
        print(f"Количество одновременных пользователей: {self.concurrent_users}")
        print("=" * 60)
        print()
        
        start_time = time.time()
        end_time = start_time + self.duration
        
        with ThreadPoolExecutor(max_workers=self.concurrent_users) as executor:
            futures = [
                executor.submit(self.worker, i, end_time)
                for i in range(1, self.concurrent_users + 1)
            ]
            
            for future in as_completed(futures):
                try:
                    worker_id, worker_results = future.result()
                    self.results['total_requests'] += worker_results['requests']
                    self.results['successful_requests'] += worker_results['successful']
                    self.results['failed_requests'] += worker_results['failed']
                    self.results['response_times'].extend(worker_results['response_times'])
                    
                    # Агрегируем ошибки и статус-коды
                    for error_type, count in worker_results['error_types'].items():
                        self.results['error_types'][error_type] = self.results['error_types'].get(error_type, 0) + count
                    for status, count in worker_results['status_codes'].items():
                        self.results['status_codes'][status] = self.results['status_codes'].get(status, 0) + count
                except Exception as e:
                    print(f"Ошибка при получении результатов воркера: {e}")
        
        self.print_results()
        return True
    
    def print_results(self):
        """Вывести результаты тестирования"""
        response_times = self.results['response_times']
        
        if not response_times:
            print("\nНет данных для анализа")
            return
        
        avg_time = statistics.mean(response_times)
        median_time = statistics.median(response_times)
        min_time = min(response_times)
        max_time = max(response_times)
        
        # Процентили
        sorted_times = sorted(response_times)
        p50 = sorted_times[int(len(sorted_times) * 0.50)] if len(sorted_times) > 0 else 0
        p95 = sorted_times[int(len(sorted_times) * 0.95)] if len(sorted_times) > 0 else 0
        p99 = sorted_times[int(len(sorted_times) * 0.99)] if len(sorted_times) > 0 else 0
        
        success_rate = (self.results['successful_requests'] / self.results['total_requests'] * 100) if self.results['total_requests'] > 0 else 0
        rps = self.results['total_requests'] / self.duration if self.duration > 0 else 0
        
        print()
        print("=" * 60)
        print("Результаты нагрузочного тестирования")
        print("=" * 60)
        print(f"Алгоритм балансировки: {self.algorithm}")
        print(f"Длительность: {self.duration} секунд")
        print(f"Всего запросов: {self.results['total_requests']}")
        print(f"Успешных: {self.results['successful_requests']} ({success_rate:.2f}%)")
        print(f"Неудачных: {self.results['failed_requests']}")
        print()
        
        # Вывод типов ошибок
        if self.results.get('error_types'):
            print("Типы ошибок:")
            for error_type, count in sorted(self.results['error_types'].items(), key=lambda x: x[1], reverse=True):
                error_percent = (count / self.results['failed_requests'] * 100) if self.results['failed_requests'] > 0 else 0
                print(f"  {error_type}: {count} ({error_percent:.1f}% от ошибок)")
            print()
        
        # Вывод статус-кодов
        if self.results.get('status_codes'):
            print("Статус-коды ответов:")
            for status, count in sorted(self.results['status_codes'].items()):
                status_percent = (count / self.results['total_requests'] * 100) if self.results['total_requests'] > 0 else 0
                status_name = {
                    200: "OK",
                    401: "Unauthorized",
                    403: "Forbidden",
                    404: "Not Found",
                    500: "Internal Server Error",
                    502: "Bad Gateway",
                    503: "Service Unavailable",
                    504: "Gateway Timeout",
                    0: "Connection Error/Timeout"
                }.get(status, f"HTTP {status}")
                print(f"  {status} ({status_name}): {count} ({status_percent:.1f}%)")
            print()
        
        print("Время ответа:")
        print(f"  Среднее: {avg_time:.2f} мс")
        print(f"  Медиана: {median_time:.2f} мс")
        print(f"  Минимальное: {min_time:.2f} мс")
        print(f"  Максимальное: {max_time:.2f} мс")
        print(f"  P50: {p50:.2f} мс")
        print(f"  P95: {p95:.2f} мс")
        print(f"  P99: {p99:.2f} мс")
        print(f"  RPS (запросов/сек): {rps:.2f}")
        print("=" * 60)
        print()
        # input("Нажмите Enter для выхода...")


def main():
    if len(sys.argv) < 2:
        print("Использование: python3 load-test.py <api-gateway-url> [algorithm] [duration] [concurrent-users]")
        print("Пример: python3 load-test.py http://localhost:4040 round-robin 30 5")
        print()
        print("Параметры:")
        print("  api-gateway-url  - URL API Gateway (обязательно)")
        print("  algorithm        - алгоритм балансировки (по умолчанию: round-robin)")
        print("  duration         - длительность в секундах (по умолчанию: 30)")
        print("  concurrent-users - количество пользователей (по умолчанию: 5)")
        sys.exit(1)
    
    api_gateway_url = sys.argv[1]
    algorithm = sys.argv[2] if len(sys.argv) > 2 else "round-robin"
    duration = sys.argv[3] if len(sys.argv) > 3 else "30"
    concurrent_users = sys.argv[4] if len(sys.argv) > 4 else "5"
    
    # Валидация параметров
    try:
        duration_int = int(duration)
        concurrent_users_int = int(concurrent_users)
        if duration_int <= 0:
            print("Ошибка: длительность должна быть положительным числом")
            sys.exit(1)
        if concurrent_users_int <= 0:
            print("Ошибка: количество пользователей должно быть положительным числом")
            sys.exit(1)
        if concurrent_users_int > 1000:
            print("Предупреждение: очень большое количество пользователей может привести к проблемам")
    except ValueError:
        print("Ошибка: длительность и количество пользователей должны быть числами")
        sys.exit(1)
    
    try:
        tester = LoadTester(api_gateway_url, algorithm, duration, concurrent_users)
        success = tester.run()
        if not success:
            sys.exit(1)
        sys.exit(0)
    except KeyboardInterrupt:
        print("\n\nТестирование прервано пользователем")
        sys.exit(130)
    except ValueError as e:
        print(f"\nОшибка параметров: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\nКритическая ошибка: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
