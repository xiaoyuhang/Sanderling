#!/usr/bin/env python3
"""
EVE Online 行星开发自动化API服务器
支持一键重新采集和自动收取功能
"""

import json
import time
import random
import threading
from datetime import datetime, timedelta
from flask import Flask, jsonify, request, Response
from flask_cors import CORS
from dataclasses import dataclass, asdict
from typing import List, Dict, Optional, Any
from enum import Enum
import uuid

app = Flask(__name__)
CORS(app)

# 自动化状态枚举
class AutomationStatus(Enum):
    IDLE = "idle"
    PLANNING = "planning"
    EXECUTING = "executing"
    PAUSED = "paused"
    COMPLETED = "completed"
    FAILED = "failed"

class AutomationStep(Enum):
    UNDOCKING = "undocking_from_station"
    NAVIGATING = "navigating_to_system"
    WARPING = "warping_to_planet"
    APPROACHING = "approaching_customs_office"
    ACCESSING = "accessing_customs_office"
    TRANSFERRING = "transferring_cargo"
    RETURNING = "returning_to_station"
    DOCKING = "docking_at_station"
    OPENING_PI = "opening_planetary_interface"
    STOPPING_EXTRACTION = "stopping_current_extraction"
    ANALYZING_RESOURCES = "analyzing_resource_distribution"
    SELECTING_LOCATION = "selecting_optimal_location"
    CONFIGURING_EXTRACTION = "configuring_new_extraction"
    STARTING_CYCLE = "starting_extraction_cycle"

# 数据类
@dataclass
class SpaceCoordinates:
    x: float
    y: float
    z: float

@dataclass
class StationInfo:
    station_id: str
    station_name: str
    system_name: str
    region_name: str
    coordinates: SpaceCoordinates

@dataclass
class PlanetCollectionTarget:
    planet_id: str
    planet_name: str
    system_name: str
    customs_office_id: str
    enabled: bool
    priority: int
    expected_cargo: float
    last_collection_time: Optional[str]

@dataclass
class ExtractorRestartConfig:
    colony_id: str
    extractor_id: str
    target_resource_type: str
    search_radius: float
    min_resource_density: float
    cycle_duration: int
    auto_optimize: bool

@dataclass
class CollectionConfig:
    character_name: str
    home_station: StationInfo
    target_planets: List[PlanetCollectionTarget]
    cargo_hold_reserve: float
    max_travel_time: int

@dataclass
class CollectedItem:
    item_type: str
    quantity: int
    volume: float
    estimated_value: float
    planet_source: str

@dataclass
class ExtractorRestartResult:
    extractor_id: str
    old_location: SpaceCoordinates
    new_location: SpaceCoordinates
    old_density: float
    new_density: float
    improvement_percentage: float

@dataclass
class AutomationResult:
    action_id: str
    action_type: str
    start_time: str
    end_time: str
    success: bool
    items_collected: List[CollectedItem]
    extractors_restarted: List[ExtractorRestartResult]
    total_value: float
    errors: List[str]
    warnings: List[str]

@dataclass
class AutomationTask:
    task_id: str
    action_type: str
    status: AutomationStatus
    current_step: Optional[AutomationStep]
    progress: float
    start_time: str
    estimated_completion: Optional[str]
    config: Dict[str, Any]
    result: Optional[AutomationResult]
    error_message: Optional[str]

# 全局状态
automation_tasks: Dict[str, AutomationTask] = {}
automation_stats = {
    "total_actions_executed": 0,
    "successful_actions": 0,
    "failed_actions": 0,
    "total_items_collected": 0,
    "total_value_collected": 0.0,
    "extractors_optimized": 0,
    "average_improvement_percentage": 0.0,
    "last_action_time": None
}

# 模拟数据
sample_home_station = StationInfo(
    station_id="station_1",
    station_name="Jita IV - Moon 4 - Caldari Navy Assembly Plant",
    system_name="Jita",
    region_name="The Forge",
    coordinates=SpaceCoordinates(x=1000.0, y=2000.0, z=3000.0)
)

sample_planets = [
    PlanetCollectionTarget(
        planet_id="planet_1",
        planet_name="Jita IV - Moon 4",
        system_name="Jita",
        customs_office_id="customs_1",
        enabled=True,
        priority=1,
        expected_cargo=5000.0,
        last_collection_time="2025-11-05T10:00:00Z"
    ),
    PlanetCollectionTarget(
        planet_id="planet_2",
        planet_name="Dodixie IX - Moon 20",
        system_name="Dodixie",
        customs_office_id="customs_2",
        enabled=True,
        priority=2,
        expected_cargo=3200.0,
        last_collection_time="2025-11-05T08:30:00Z"
    ),
    PlanetCollectionTarget(
        planet_id="planet_3",
        planet_name="Amarr VIII (Oris)",
        system_name="Amarr",
        customs_office_id="customs_3",
        enabled=False,  # 指定不收取
        priority=3,
        expected_cargo=1800.0,
        last_collection_time="2025-11-04T15:20:00Z"
    )
]

def generate_task_id():
    """生成唯一任务ID"""
    return str(uuid.uuid4())

def simulate_automation_task(task: AutomationTask):
    """模拟自动化任务执行"""
    def run_task():
        try:
            if task.action_type == "extractor_restart":
                simulate_extractor_restart(task)
            elif task.action_type == "resource_collection":
                simulate_resource_collection(task)
        except Exception as e:
            task.status = AutomationStatus.FAILED
            task.error_message = str(e)
            automation_stats["failed_actions"] += 1

    thread = threading.Thread(target=run_task)
    thread.daemon = True
    thread.start()

def simulate_extractor_restart(task: AutomationTask):
    """模拟提取器重启过程"""
    steps = [
        (AutomationStep.OPENING_PI, "正在打开行星界面...", 2),
        (AutomationStep.STOPPING_EXTRACTION, "正在停止当前采集...", 1),
        (AutomationStep.ANALYZING_RESOURCES, "正在分析资源分布...", 5),
        (AutomationStep.SELECTING_LOCATION, "正在选择最佳位置...", 2),
        (AutomationStep.CONFIGURING_EXTRACTION, "正在配置新的采集程序...", 3),
        (AutomationStep.STARTING_CYCLE, "正在启动采集周期...", 1)
    ]
    
    task.status = AutomationStatus.EXECUTING
    total_duration = sum(duration for _, _, duration in steps)
    elapsed_time = 0
    
    for step, description, duration in steps:
        task.current_step = step
        print(f"[{task.task_id}] {description}")
        
        # 模拟步骤执行
        for i in range(duration):
            time.sleep(1)
            elapsed_time += 1
            task.progress = (elapsed_time / total_duration) * 100
    
    # 生成结果
    old_location = SpaceCoordinates(x=100.0, y=200.0, z=50.0)
    new_location = SpaceCoordinates(x=150.0, y=180.0, z=60.0)
    old_density = random.uniform(0.6, 0.8)
    new_density = random.uniform(0.85, 0.95)
    improvement = ((new_density - old_density) / old_density) * 100
    
    restart_result = ExtractorRestartResult(
        extractor_id=task.config.get("extractor_id", "extractor_1"),
        old_location=old_location,
        new_location=new_location,
        old_density=old_density,
        new_density=new_density,
        improvement_percentage=improvement
    )
    
    task.result = AutomationResult(
        action_id=task.task_id,
        action_type="extractor_restart",
        start_time=task.start_time,
        end_time=datetime.now().isoformat(),
        success=True,
        items_collected=[],
        extractors_restarted=[restart_result],
        total_value=0.0,
        errors=[],
        warnings=[]
    )
    
    task.status = AutomationStatus.COMPLETED
    task.progress = 100.0
    
    # 更新统计
    automation_stats["total_actions_executed"] += 1
    automation_stats["successful_actions"] += 1
    automation_stats["extractors_optimized"] += 1
    automation_stats["last_action_time"] = datetime.now().isoformat()

def simulate_resource_collection(task: AutomationTask):
    """模拟资源收取过程"""
    config = task.config
    enabled_planets = [p for p in config.get("target_planets", []) if p.get("enabled", True)]
    
    steps = [
        (AutomationStep.UNDOCKING, "正在离开空间站...", 2),
    ]
    
    # 为每个行星添加步骤
    for planet in enabled_planets:
        steps.extend([
            (AutomationStep.NAVIGATING, f"正在跳跃到 {planet['system_name']} 星系...", 5),
            (AutomationStep.WARPING, f"正在跃迁到 {planet['planet_name']}...", 3),
            (AutomationStep.APPROACHING, "正在接近海关办公室...", 2),
            (AutomationStep.ACCESSING, "正在访问海关办公室...", 1),
            (AutomationStep.TRANSFERRING, "正在转移货物...", 3)
        ])
    
    steps.extend([
        (AutomationStep.RETURNING, "正在返回空间站...", 5),
        (AutomationStep.DOCKING, "正在停靠空间站...", 2)
    ])
    
    task.status = AutomationStatus.EXECUTING
    total_duration = sum(duration for _, _, duration in steps)
    elapsed_time = 0
    
    collected_items = []
    total_value = 0.0
    
    for step, description, duration in steps:
        task.current_step = step
        print(f"[{task.task_id}] {description}")
        
        # 模拟货物收集
        if step == AutomationStep.TRANSFERRING:
            # 随机生成收集的物品
            item_types = ["Base Metals", "Aqueous Liquids", "Heavy Metals", "Carbon Compounds"]
            for item_type in random.sample(item_types, random.randint(1, 3)):
                quantity = random.randint(100, 1000)
                volume = quantity * random.uniform(0.1, 2.0)
                value = quantity * random.uniform(10, 50)
                
                item = CollectedItem(
                    item_type=item_type,
                    quantity=quantity,
                    volume=volume,
                    estimated_value=value,
                    planet_source=description.split("到 ")[1].split("...")[0] if "到 " in description else "Unknown"
                )
                collected_items.append(item)
                total_value += value
        
        # 模拟步骤执行
        for i in range(duration):
            time.sleep(1)
            elapsed_time += 1
            task.progress = (elapsed_time / total_duration) * 100
    
    # 生成结果
    task.result = AutomationResult(
        action_id=task.task_id,
        action_type="resource_collection",
        start_time=task.start_time,
        end_time=datetime.now().isoformat(),
        success=True,
        items_collected=collected_items,
        extractors_restarted=[],
        total_value=total_value,
        errors=[],
        warnings=[]
    )
    
    task.status = AutomationStatus.COMPLETED
    task.progress = 100.0
    
    # 更新统计
    automation_stats["total_actions_executed"] += 1
    automation_stats["successful_actions"] += 1
    automation_stats["total_items_collected"] += sum(item.quantity for item in collected_items)
    automation_stats["total_value_collected"] += total_value
    automation_stats["last_action_time"] = datetime.now().isoformat()

# API 端点

@app.route('/api/automation/extractor/restart', methods=['POST'])
def start_extractor_restart():
    """启动提取器重启"""
    try:
        data = request.get_json()
        
        config = ExtractorRestartConfig(
            colony_id=data.get('colony_id', 'colony_1'),
            extractor_id=data.get('extractor_id', 'extractor_1'),
            target_resource_type=data.get('target_resource_type', 'Base Metals'),
            search_radius=data.get('search_radius', 10.0),
            min_resource_density=data.get('min_resource_density', 0.8),
            cycle_duration=data.get('cycle_duration', 24),
            auto_optimize=data.get('auto_optimize', True)
        )
        
        task_id = generate_task_id()
        task = AutomationTask(
            task_id=task_id,
            action_type="extractor_restart",
            status=AutomationStatus.PLANNING,
            current_step=None,
            progress=0.0,
            start_time=datetime.now().isoformat(),
            estimated_completion=(datetime.now() + timedelta(minutes=2)).isoformat(),
            config=asdict(config),
            result=None,
            error_message=None
        )
        
        automation_tasks[task_id] = task
        simulate_automation_task(task)
        
        return jsonify({
            "success": True,
            "task_id": task_id,
            "message": "提取器重启任务已启动",
            "estimated_completion": task.estimated_completion
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 400

@app.route('/api/automation/collection/start', methods=['POST'])
def start_resource_collection():
    """启动资源收取"""
    try:
        data = request.get_json()
        
        # 使用提供的配置或默认配置
        target_planets = data.get('target_planets', [asdict(p) for p in sample_planets])
        
        config = CollectionConfig(
            character_name=data.get('character_name', 'TestPilot'),
            home_station=sample_home_station,
            target_planets=target_planets,
            cargo_hold_reserve=data.get('cargo_hold_reserve', 10.0),
            max_travel_time=data.get('max_travel_time', 60)
        )
        
        task_id = generate_task_id()
        enabled_planets = [p for p in target_planets if p.get('enabled', True)]
        estimated_minutes = len(enabled_planets) * 15 + 10  # 每个行星15分钟 + 往返时间
        
        task = AutomationTask(
            task_id=task_id,
            action_type="resource_collection",
            status=AutomationStatus.PLANNING,
            current_step=None,
            progress=0.0,
            start_time=datetime.now().isoformat(),
            estimated_completion=(datetime.now() + timedelta(minutes=estimated_minutes)).isoformat(),
            config=asdict(config),
            result=None,
            error_message=None
        )
        
        automation_tasks[task_id] = task
        simulate_automation_task(task)
        
        return jsonify({
            "success": True,
            "task_id": task_id,
            "message": f"资源收取任务已启动，将访问 {len(enabled_planets)} 个行星",
            "estimated_completion": task.estimated_completion,
            "target_planets": [p['planet_name'] for p in enabled_planets]
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 400

@app.route('/api/automation/task/<task_id>', methods=['GET'])
def get_task_status(task_id):
    """获取任务状态"""
    if task_id not in automation_tasks:
        return jsonify({
            "success": False,
            "error": "任务不存在"
        }), 404
    
    task = automation_tasks[task_id]
    
    response = {
        "task_id": task.task_id,
        "action_type": task.action_type,
        "status": task.status.value,
        "progress": task.progress,
        "start_time": task.start_time,
        "estimated_completion": task.estimated_completion
    }
    
    if task.current_step:
        response["current_step"] = task.current_step.value
    
    if task.result:
        response["result"] = asdict(task.result)
    
    if task.error_message:
        response["error_message"] = task.error_message
    
    return jsonify(response)

@app.route('/api/automation/task/<task_id>/cancel', methods=['POST'])
def cancel_task(task_id):
    """取消任务"""
    if task_id not in automation_tasks:
        return jsonify({
            "success": False,
            "error": "任务不存在"
        }), 404
    
    task = automation_tasks[task_id]
    
    if task.status in [AutomationStatus.COMPLETED, AutomationStatus.FAILED]:
        return jsonify({
            "success": False,
            "error": "任务已完成，无法取消"
        }), 400
    
    task.status = AutomationStatus.FAILED
    task.error_message = "用户取消"
    
    return jsonify({
        "success": True,
        "message": "任务已取消"
    })

@app.route('/api/automation/tasks', methods=['GET'])
def get_all_tasks():
    """获取所有任务"""
    tasks = []
    for task in automation_tasks.values():
        task_info = {
            "task_id": task.task_id,
            "action_type": task.action_type,
            "status": task.status.value,
            "progress": task.progress,
            "start_time": task.start_time
        }
        
        if task.current_step:
            task_info["current_step"] = task.current_step.value
        
        if task.result:
            task_info["total_value"] = task.result.total_value
            task_info["items_collected"] = len(task.result.items_collected)
        
        tasks.append(task_info)
    
    return jsonify({
        "tasks": tasks,
        "total_tasks": len(tasks)
    })

@app.route('/api/automation/stats', methods=['GET'])
def get_automation_stats():
    """获取自动化统计"""
    return jsonify(automation_stats)

@app.route('/api/automation/config/planets', methods=['GET'])
def get_planet_config():
    """获取行星配置"""
    return jsonify({
        "home_station": asdict(sample_home_station),
        "available_planets": [asdict(p) for p in sample_planets]
    })

@app.route('/api/automation/config/planets', methods=['POST'])
def update_planet_config():
    """更新行星配置"""
    try:
        data = request.get_json()
        
        # 更新行星配置
        for planet_data in data.get('planets', []):
            for planet in sample_planets:
                if planet.planet_id == planet_data.get('planet_id'):
                    planet.enabled = planet_data.get('enabled', planet.enabled)
                    planet.priority = planet_data.get('priority', planet.priority)
        
        return jsonify({
            "success": True,
            "message": "行星配置已更新",
            "updated_planets": [asdict(p) for p in sample_planets]
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 400

@app.route('/api/automation/safety/check', methods=['GET'])
def safety_check():
    """安全检查"""
    # 模拟安全检查
    safety_status = {
        "overall_safe": True,
        "checks": {
            "hostile_players": {"safe": True, "message": "未检测到敌对玩家"},
            "security_status": {"safe": True, "message": "当前系统安全等级: 1.0"},
            "ship_status": {"safe": True, "message": "飞船状态良好"},
            "cargo_space": {"safe": True, "message": "货舱空间充足"},
            "route_safety": {"safe": True, "message": "航线安全"}
        },
        "warnings": [],
        "recommendations": [
            "建议在高峰时段避免低安全区域",
            "定期检查飞船装备状态"
        ]
    }
    
    return jsonify(safety_status)

@app.route('/api/automation/emergency/stop', methods=['POST'])
def emergency_stop():
    """紧急停止所有自动化操作"""
    stopped_tasks = []
    
    for task_id, task in automation_tasks.items():
        if task.status in [AutomationStatus.EXECUTING, AutomationStatus.PLANNING]:
            task.status = AutomationStatus.FAILED
            task.error_message = "紧急停止"
            stopped_tasks.append(task_id)
    
    return jsonify({
        "success": True,
        "message": f"已停止 {len(stopped_tasks)} 个任务",
        "stopped_tasks": stopped_tasks
    })

@app.route('/api/automation/logs/<task_id>', methods=['GET'])
def get_task_logs(task_id):
    """获取任务日志"""
    if task_id not in automation_tasks:
        return jsonify({
            "success": False,
            "error": "任务不存在"
        }), 404
    
    # 模拟日志数据
    logs = [
        {"timestamp": "2025-11-05T11:30:00Z", "level": "INFO", "message": "任务开始执行"},
        {"timestamp": "2025-11-05T11:30:05Z", "level": "INFO", "message": "正在打开行星界面..."},
        {"timestamp": "2025-11-05T11:30:10Z", "level": "INFO", "message": "正在分析资源分布..."},
        {"timestamp": "2025-11-05T11:30:15Z", "level": "SUCCESS", "message": "找到更优位置，密度提升15%"},
        {"timestamp": "2025-11-05T11:30:20Z", "level": "INFO", "message": "正在配置新的采集程序..."},
        {"timestamp": "2025-11-05T11:30:25Z", "level": "SUCCESS", "message": "任务完成"}
    ]
    
    return jsonify({
        "task_id": task_id,
        "logs": logs
    })

if __name__ == '__main__':
    print("🚀 行星开发自动化API服务器启动在端口 12003")
    print("📡 自动化API端点:")
    print("   - POST /api/automation/extractor/restart - 启动提取器重启")
    print("   - POST /api/automation/collection/start - 启动资源收取")
    print("   - GET /api/automation/task/<task_id> - 获取任务状态")
    print("   - POST /api/automation/task/<task_id>/cancel - 取消任务")
    print("   - GET /api/automation/tasks - 获取所有任务")
    print("   - GET /api/automation/stats - 获取自动化统计")
    print("   - GET /api/automation/config/planets - 获取行星配置")
    print("   - POST /api/automation/config/planets - 更新行星配置")
    print("   - GET /api/automation/safety/check - 安全检查")
    print("   - POST /api/automation/emergency/stop - 紧急停止")
    print("   - GET /api/automation/logs/<task_id> - 获取任务日志")
    print("🌐 访问地址: http://localhost:12003")
    
    app.run(host='0.0.0.0', port=12001, debug=True)