#!/usr/bin/env python3
"""
EVE Online 行星开发状态 API 服务器
模拟从Sanderling获取行星开发数据的API端点
"""

import json
import time
import random
from datetime import datetime, timedelta
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading

class PIAPIHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        query_params = parse_qs(parsed_path.query)
        
        # 设置CORS头
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        
        if path == '/api/pi/colonies':
            self.handle_colonies_request()
        elif path == '/api/pi/colony':
            colony_id = query_params.get('id', [''])[0]
            self.handle_colony_detail_request(colony_id)
        elif path == '/api/pi/status':
            self.handle_status_request()
        elif path == '/api/pi/resources':
            self.handle_resources_request()
        else:
            self.send_error_response(404, "Endpoint not found")
    
    def do_OPTIONS(self):
        # 处理预检请求
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def handle_colonies_request(self):
        """返回所有殖民地的概览信息"""
        colonies_data = self.generate_colonies_data()
        self.wfile.write(json.dumps(colonies_data, indent=2).encode())
    
    def handle_colony_detail_request(self, colony_id):
        """返回特定殖民地的详细信息"""
        if not colony_id:
            self.send_error_response(400, "Colony ID is required")
            return
        
        colony_detail = self.generate_colony_detail(colony_id)
        self.wfile.write(json.dumps(colony_detail, indent=2).encode())
    
    def handle_status_request(self):
        """返回整体状态信息"""
        status_data = self.generate_status_data()
        self.wfile.write(json.dumps(status_data, indent=2).encode())
    
    def handle_resources_request(self):
        """返回资源信息"""
        resources_data = self.generate_resources_data()
        self.wfile.write(json.dumps(resources_data, indent=2).encode())
    
    def send_error_response(self, code, message):
        """发送错误响应"""
        error_data = {
            "error": {
                "code": code,
                "message": message,
                "timestamp": datetime.now().isoformat()
            }
        }
        self.wfile.write(json.dumps(error_data).encode())
    
    def generate_colonies_data(self):
        """生成模拟的殖民地数据"""
        current_time = datetime.now()
        
        # 模拟一些变化的数据
        base_time = int(time.time())
        variation = (base_time % 300) / 300.0  # 5分钟周期的变化
        
        colonies = [
            {
                "id": "colony_1",
                "planetName": "Jita IV - Moon 4",
                "planetType": "Temperate",
                "systemName": "Jita",
                "regionName": "The Forge",
                "securityStatus": 0.9,
                "status": "active",
                "lastUpdate": (current_time - timedelta(minutes=2)).isoformat(),
                "powerUsage": {
                    "used": int(1500 + variation * 200),
                    "total": 2000,
                    "percentage": round((1500 + variation * 200) / 2000 * 100, 1)
                },
                "cpuUsage": {
                    "used": int(750 + variation * 150),
                    "total": 1000,
                    "percentage": round((750 + variation * 150) / 1000 * 100, 1)
                },
                "commandCenterLevel": 3,
                "facilitiesCount": 5,
                "extractorsCount": 1,
                "activeExtractors": 1,
                "totalProduction": round(2500.5 + variation * 500, 1),
                "storageUsage": {
                    "used": int(4800 + variation * 1000),
                    "total": 10000,
                    "percentage": round((4800 + variation * 1000) / 10000 * 100, 1)
                }
            },
            {
                "id": "colony_2",
                "planetName": "Dodixie IX - Moon 20",
                "planetType": "Barren",
                "systemName": "Dodixie",
                "regionName": "Sinq Laison",
                "securityStatus": 0.7,
                "status": "attention",
                "lastUpdate": (current_time - timedelta(minutes=15)).isoformat(),
                "powerUsage": {
                    "used": 1800,
                    "total": 2000,
                    "percentage": 90.0
                },
                "cpuUsage": {
                    "used": 950,
                    "total": 1000,
                    "percentage": 95.0
                },
                "commandCenterLevel": 4,
                "facilitiesCount": 4,
                "extractorsCount": 1,
                "activeExtractors": 0,
                "totalProduction": 0,
                "storageUsage": {
                    "used": 3200,
                    "total": 8000,
                    "percentage": 40.0
                },
                "issues": [
                    "提取器已停止运行",
                    "处理器出现错误",
                    "CPU使用率过高"
                ]
            },
            {
                "id": "colony_3",
                "planetName": "Amarr VIII (Oris)",
                "planetType": "Oceanic",
                "systemName": "Amarr",
                "regionName": "Domain",
                "securityStatus": 1.0,
                "status": "active",
                "lastUpdate": (current_time - timedelta(minutes=1)).isoformat(),
                "powerUsage": {
                    "used": int(1200 + variation * 100),
                    "total": 1500,
                    "percentage": round((1200 + variation * 100) / 1500 * 100, 1)
                },
                "cpuUsage": {
                    "used": int(600 + variation * 80),
                    "total": 800,
                    "percentage": round((600 + variation * 80) / 800 * 100, 1)
                },
                "commandCenterLevel": 2,
                "facilitiesCount": 4,
                "extractorsCount": 1,
                "activeExtractors": 1,
                "totalProduction": round(3200.8 + variation * 400, 1),
                "storageUsage": {
                    "used": int(1500 + variation * 500),
                    "total": 10000,
                    "percentage": round((1500 + variation * 500) / 10000 * 100, 1)
                }
            }
        ]
        
        return {
            "timestamp": current_time.isoformat(),
            "totalColonies": len(colonies),
            "activeColonies": len([c for c in colonies if c["status"] == "active"]),
            "coloniesNeedingAttention": len([c for c in colonies if c["status"] == "attention"]),
            "colonies": colonies
        }
    
    def generate_colony_detail(self, colony_id):
        """生成特定殖民地的详细信息"""
        current_time = datetime.now()
        base_time = int(time.time())
        variation = (base_time % 300) / 300.0
        
        # 根据colony_id生成不同的详细数据
        if colony_id == "colony_1":
            return {
                "id": colony_id,
                "planetName": "Jita IV - Moon 4",
                "planetType": "Temperate",
                "status": "active",
                "lastUpdate": current_time.isoformat(),
                "facilities": [
                    {
                        "id": "cc_1",
                        "type": "Command Center",
                        "level": 3,
                        "status": "active",
                        "powerConsumption": 0,
                        "cpuConsumption": 0,
                        "position": {"x": 150, "y": 80},
                        "upgradeAvailable": True
                    },
                    {
                        "id": "ext_1",
                        "type": "Extractor",
                        "status": "active",
                        "powerConsumption": 800,
                        "cpuConsumption": 400,
                        "position": {"x": 200, "y": 120},
                        "resourceType": "Base Metals",
                        "extractionRate": round(2500.5 + variation * 500, 1),
                        "cycleTime": 24,
                        "headsCount": 5,
                        "efficiency": round(85 + variation * 10, 1)
                    },
                    {
                        "id": "proc_1",
                        "type": "Processor",
                        "tier": "Basic",
                        "status": "active",
                        "powerConsumption": 400,
                        "cpuConsumption": 200,
                        "position": {"x": 180, "y": 150},
                        "schematic": "Refined Metals",
                        "cyclesRemaining": int(10 + variation * 5),
                        "inputMaterials": [
                            {"type": "Base Metals", "quantity": 3000}
                        ],
                        "outputProducts": [
                            {"type": "Refined Metals", "quantity": 20}
                        ]
                    },
                    {
                        "id": "storage_1",
                        "type": "Storage Unit",
                        "status": "active" if variation < 0.8 else "full",
                        "powerConsumption": 150,
                        "cpuConsumption": 75,
                        "position": {"x": 220, "y": 100},
                        "capacity": 5000,
                        "used": int(4800 + variation * 200),
                        "contents": [
                            {"type": "Base Metals", "quantity": int(3000 + variation * 500)},
                            {"type": "Refined Metals", "quantity": int(50 + variation * 20)}
                        ]
                    },
                    {
                        "id": "launch_1",
                        "type": "Launchpad",
                        "status": "active",
                        "powerConsumption": 150,
                        "cpuConsumption": 75,
                        "position": {"x": 120, "y": 140},
                        "capacity": 10000,
                        "used": int(2500 + variation * 1000),
                        "pendingTransfers": [
                            {
                                "type": "export",
                                "destination": "Jita IV - Moon 4 - Caldari Navy Assembly Plant",
                                "items": [{"type": "Refined Metals", "quantity": 100}],
                                "estimatedTime": (current_time + timedelta(hours=2)).isoformat()
                            }
                        ]
                    }
                ],
                "links": [
                    {
                        "id": "link_1",
                        "from": "ext_1",
                        "to": "storage_1",
                        "length": 45.2,
                        "powerConsumption": 50,
                        "cpuConsumption": 25,
                        "isActive": True
                    },
                    {
                        "id": "link_2",
                        "from": "storage_1",
                        "to": "proc_1",
                        "length": 32.1,
                        "powerConsumption": 35,
                        "cpuConsumption": 18,
                        "isActive": True
                    }
                ],
                "routes": [
                    {
                        "id": "route_1",
                        "source": "ext_1",
                        "destination": "storage_1",
                        "materialType": "Base Metals",
                        "quantity": 1000,
                        "isActive": True
                    }
                ],
                "extractionProgram": {
                    "startTime": (current_time - timedelta(hours=12)).isoformat(),
                    "duration": 24,
                    "currentCycle": 1,
                    "totalCycles": 7,
                    "timeRemaining": int(12 * 3600 - variation * 3600),
                    "nextCycleTime": (current_time + timedelta(hours=12)).isoformat()
                }
            }
        else:
            # 为其他殖民地返回基本信息
            return {
                "id": colony_id,
                "planetName": f"Planet {colony_id}",
                "status": "active",
                "lastUpdate": current_time.isoformat(),
                "facilities": [],
                "message": "详细数据加载中..."
            }
    
    def generate_status_data(self):
        """生成整体状态数据"""
        current_time = datetime.now()
        colonies_data = self.generate_colonies_data()
        
        total_production = sum(c.get("totalProduction", 0) for c in colonies_data["colonies"])
        total_extractors = sum(c.get("extractorsCount", 0) for c in colonies_data["colonies"])
        active_extractors = sum(c.get("activeExtractors", 0) for c in colonies_data["colonies"])
        
        return {
            "timestamp": current_time.isoformat(),
            "summary": {
                "totalColonies": colonies_data["totalColonies"],
                "activeColonies": colonies_data["activeColonies"],
                "coloniesNeedingAttention": colonies_data["coloniesNeedingAttention"],
                "totalExtractors": total_extractors,
                "activeExtractors": active_extractors,
                "totalProductionPerHour": round(total_production, 1),
                "averageEfficiency": round(active_extractors / max(total_extractors, 1) * 100, 1)
            },
            "alerts": [
                {
                    "level": "warning",
                    "colony": "Dodixie IX - Moon 20",
                    "message": "提取器已停止运行",
                    "timestamp": (current_time - timedelta(minutes=15)).isoformat()
                },
                {
                    "level": "info",
                    "colony": "Jita IV - Moon 4",
                    "message": "存储单元接近满载",
                    "timestamp": (current_time - timedelta(minutes=5)).isoformat()
                }
            ],
            "performance": {
                "dataFreshness": "实时",
                "lastScanTime": current_time.isoformat(),
                "scanDuration": "0.5秒",
                "memoryReadingStatus": "正常"
            }
        }
    
    def generate_resources_data(self):
        """生成资源信息数据"""
        current_time = datetime.now()
        base_time = int(time.time())
        variation = (base_time % 600) / 600.0  # 10分钟周期
        
        resources = [
            {
                "type": "Base Metals",
                "totalExtracted": int(50000 + variation * 10000),
                "currentRate": round(2500.5 + variation * 500, 1),
                "averageDensity": round(0.75 + variation * 0.2, 2),
                "planetsWithResource": 2,
                "marketValue": round(15.5 + variation * 2, 2)
            },
            {
                "type": "Heavy Metals",
                "totalExtracted": int(25000 + variation * 5000),
                "currentRate": 0,
                "averageDensity": round(0.65 + variation * 0.15, 2),
                "planetsWithResource": 1,
                "marketValue": round(25.8 + variation * 3, 2)
            },
            {
                "type": "Aqueous Liquids",
                "totalExtracted": int(75000 + variation * 15000),
                "currentRate": round(3200.8 + variation * 400, 1),
                "averageDensity": round(0.85 + variation * 0.1, 2),
                "planetsWithResource": 1,
                "marketValue": round(8.2 + variation * 1, 2)
            }
        ]
        
        return {
            "timestamp": current_time.isoformat(),
            "resources": resources,
            "totalValue": sum(r["totalExtracted"] * r["marketValue"] for r in resources),
            "dailyProduction": sum(r["currentRate"] * 24 for r in resources)
        }

def run_server(port=12001):
    """启动API服务器"""
    server_address = ('0.0.0.0', port)
    httpd = HTTPServer(server_address, PIAPIHandler)
    print(f"🚀 行星开发API服务器启动在端口 {port}")
    print(f"📡 API端点:")
    print(f"   - GET /api/pi/colonies - 获取所有殖民地")
    print(f"   - GET /api/pi/colony?id=<colony_id> - 获取特定殖民地详情")
    print(f"   - GET /api/pi/status - 获取整体状态")
    print(f"   - GET /api/pi/resources - 获取资源信息")
    print(f"🌐 访问地址: http://localhost:{port}")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 服务器已停止")
        httpd.shutdown()

if __name__ == "__main__":
    run_server()