#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Скрипт для генерации ConfigMap из файлов дашбордов
"""

import os
import base64
import yaml

def generate_configmap():
    dashboards_dir = 'dashboards'
    configmap_data = {
        'apiVersion': 'v1',
        'kind': 'ConfigMap',
        'metadata': {
            'name': 'grafana-dashboards',
            'namespace': 'microservices-lab'
        },
        'data': {}
    }
    
    # Читаем все файлы из директории
    for filename in sorted(os.listdir(dashboards_dir)):
        filepath = os.path.join(dashboards_dir, filename)
        # Игнорируем README, dashboards.yml (он в отдельном ConfigMap) и другие не-JSON файлы
        if os.path.isfile(filepath) and filename.endswith('.json'):
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            configmap_data['data'][filename] = content
            print(f'✓ Added {filename}')
    
    # Записываем ConfigMap
    output_file = 'manifests/configs/grafana-dashboards-configmap.yaml'
    with open(output_file, 'w', encoding='utf-8') as f:
        yaml.dump(configmap_data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
    
    print(f'\n✓ Generated {output_file}')

if __name__ == '__main__':
    try:
        import yaml
    except ImportError:
        print("Error: PyYAML not installed. Install with: pip install pyyaml")
        exit(1)
    
    generate_configmap()

