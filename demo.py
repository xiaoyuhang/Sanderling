#!/usr/bin/env python3
"""
EVE Online 行星开发状态监控系统演示脚本
"""

import time
import requests
import json
from datetime import datetime

def print_banner():
    """打印横幅"""
    print("=" * 80)
    print("🌍 EVE Online 行星开发状态监控系统演示")
    print("=" * 80)
    print()

def test_api_endpoints():
    """测试API端点"""
    base_url = "http://localhost:12001/api/pi"
    endpoints = [
        ("/status", "整体状态"),
        ("/colonies", "殖民地概览"),
        ("/colony?id=colony_1", "殖民地详情"),
        ("/resources", "资源统计")
    ]
    
    print("📡 测试API端点:")
    print("-" * 40)
    
    for endpoint, description in endpoints:
        try:
            response = requests.get(f"{base_url}{endpoint}", timeout=5)
            if response.status_code == 200:
                print(f"✅ {description}: {endpoint} - 正常")
            else:
                print(f"❌ {description}: {endpoint} - 错误 ({response.status_code})")
        except Exception as e:
            print(f"❌ {description}: {endpoint} - 连接失败")
    
    print()

def show_colony_summary():
    """显示殖民地摘要"""
    try:
        response = requests.get("http://localhost:12001/api/pi/status", timeout=5)
        if response.status_code == 200:
            data = response.json()
            summary = data.get("summary", {})
            
            print("📊 殖民地状态摘要:")
            print("-" * 40)
            print(f"总殖民地数量: {summary.get('totalColonies', 0)}")
            print(f"活跃殖民地: {summary.get('activeColonies', 0)}")
            print(f"需要关注: {summary.get('coloniesNeedingAttention', 0)}")
            print(f"总提取器: {summary.get('totalExtractors', 0)}")
            print(f"活跃提取器: {summary.get('activeExtractors', 0)}")
            print(f"每小时总产量: {summary.get('totalProductionPerHour', 0):.1f} 单位")
            print(f"平均效率: {summary.get('averageEfficiency', 0):.1f}%")
            print()
            
            # 显示警报
            alerts = data.get("alerts", [])
            if alerts:
                print("🚨 当前警报:")
                print("-" * 40)
                for alert in alerts:
                    level_icon = "⚠️" if alert["level"] == "warning" else "ℹ️"
                    print(f"{level_icon} {alert['colony']}: {alert['message']}")
                print()
        else:
            print("❌ 无法获取状态数据")
    except Exception as e:
        print(f"❌ 连接API失败: {e}")

def show_colony_details():
    """显示殖民地详情"""
    try:
        response = requests.get("http://localhost:12001/api/pi/colonies", timeout=5)
        if response.status_code == 200:
            data = response.json()
            colonies = data.get("colonies", [])
            
            print("🌍 殖民地详情:")
            print("-" * 40)
            
            for colony in colonies:
                status_icon = {
                    "active": "🟢",
                    "inactive": "🔴", 
                    "attention": "🟡",
                    "error": "🔴"
                }.get(colony.get("status", "inactive"), "⚪")
                
                print(f"{status_icon} {colony.get('planetName', 'Unknown')}")
                print(f"   类型: {colony.get('planetType', 'Unknown')}")
                print(f"   星系: {colony.get('systemName', 'Unknown')} ({colony.get('securityStatus', 0.0)})")
                print(f"   指挥中心等级: {colony.get('commandCenterLevel', 0)}")
                
                power = colony.get('powerUsage', {})
                cpu = colony.get('cpuUsage', {})
                print(f"   电力: {power.get('used', 0)}/{power.get('total', 0)} MW ({power.get('percentage', 0):.1f}%)")
                print(f"   CPU: {cpu.get('used', 0)}/{cpu.get('total', 0)} tf ({cpu.get('percentage', 0):.1f}%)")
                print(f"   产量: {colony.get('totalProduction', 0):.1f} 单位/小时")
                
                if colony.get('issues'):
                    print(f"   ⚠️ 问题: {', '.join(colony['issues'])}")
                
                print()
        else:
            print("❌ 无法获取殖民地数据")
    except Exception as e:
        print(f"❌ 连接API失败: {e}")

def show_resource_summary():
    """显示资源摘要"""
    try:
        response = requests.get("http://localhost:12001/api/pi/resources", timeout=5)
        if response.status_code == 200:
            data = response.json()
            resources = data.get("resources", [])
            
            print("📦 资源统计:")
            print("-" * 40)
            print(f"总价值: {data.get('totalValue', 0):,.0f} ISK")
            print(f"日产量: {data.get('dailyProduction', 0):,.0f} 单位")
            print()
            
            for resource in resources:
                status_icon = "🟢" if resource.get('currentRate', 0) > 0 else "🔴"
                print(f"{status_icon} {resource.get('type', 'Unknown')}")
                print(f"   总提取: {resource.get('totalExtracted', 0):,} 单位")
                print(f"   当前速率: {resource.get('currentRate', 0):.1f} 单位/小时")
                print(f"   平均密度: {resource.get('averageDensity', 0):.2f}")
                print(f"   市场价格: {resource.get('marketValue', 0):.2f} ISK")
                daily_value = resource.get('currentRate', 0) * 24 * resource.get('marketValue', 0)
                print(f"   日价值: {daily_value:,.0f} ISK")
                print()
        else:
            print("❌ 无法获取资源数据")
    except Exception as e:
        print(f"❌ 连接API失败: {e}")

def show_access_info():
    """显示访问信息"""
    print("🌐 Web界面访问地址:")
    print("-" * 40)
    print("基础版仪表板:")
    print("https://work-1-klycxfekopkjwjtm.prod-runtime.all-hands.dev/pi_dashboard.html")
    print()
    print("增强版仪表板 (推荐):")
    print("https://work-1-klycxfekopkjwjtm.prod-runtime.all-hands.dev/pi_dashboard_enhanced.html")
    print()
    print("API端点:")
    print("http://localhost:12001/api/pi/status")
    print("http://localhost:12001/api/pi/colonies")
    print("http://localhost:12001/api/pi/resources")
    print()

def main():
    """主函数"""
    print_banner()
    
    print("🚀 正在启动演示...")
    print()
    
    # 等待服务启动
    time.sleep(2)
    
    # 测试API
    test_api_endpoints()
    
    # 显示各种信息
    show_colony_summary()
    show_colony_details()
    show_resource_summary()
    show_access_info()
    
    print("✨ 演示完成！")
    print()
    print("💡 提示:")
    print("- 访问Web界面查看完整的可视化仪表板")
    print("- API数据每次请求都会有轻微变化，模拟实时更新")
    print("- 增强版仪表板支持自动刷新和详细信息查看")
    print("- 所有数据都是模拟的，用于演示功能")
    print()

if __name__ == "__main__":
    main()