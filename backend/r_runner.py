#!/usr/bin/env python3
# R脚本运行器

import subprocess
import json
import os
from pathlib import Path

class RRunner:
    def __init__(self, r_scripts_dir="R_scripts", data_dir="data"):
        self.r_scripts_dir = Path(r_scripts_dir)
        self.data_dir = Path(data_dir)
        self.results_dir = self.data_dir / "processed" / "analysis_results"
        
        # 创建目录（如果不存在）
        try:
            self.results_dir.mkdir(parents=True, exist_ok=True)
        except OSError:
            # 如果无法创建目录，使用当前目录
            self.results_dir = Path('.')
    
    def run_analysis(self, analysis_type, parameters):
        """运行R分析脚本"""
        script_map = {
            'differential_expression': 'deseq2_analysis.R',
            'pca_analysis': 'pca_analysis.R',
            'enrichment_analysis': 'enrichment_analysis.R',
            'survival_analysis': 'survival_analysis.R'
        }
        
        script_name = script_map.get(analysis_type)
        if not script_name:
            raise ValueError(f"Unknown analysis type: {analysis_type}")
        
        script_path = self.r_scripts_dir / script_name
        
        if not script_path.exists():
            raise FileNotFoundError(f"R script not found: {script_path}")
        
        # 准备输入和输出文件
        input_file = self.results_dir / f"{analysis_type}_input.json"
        output_file = self.results_dir / f"{analysis_type}_output.json"
        
        # 写入输入参数
        with open(input_file, 'w') as f:
            json.dump(parameters, f, indent=2)
        
        # 运行R脚本
        cmd = [
            'Rscript', str(script_path),
            '--input', str(input_file),
            '--output', str(output_file)
        ]
        
        try:
            result = subprocess.run(
                cmd, 
                capture_output=True, 
                text=True, 
                check=True,
                cwd=os.getcwd()
            )
            
            # 读取结果
            if output_file.exists():
                with open(output_file, 'r') as f:
                    return json.load(f)
            else:
                return {
                    'status': 'completed',
                    'message': 'Analysis completed successfully',
                    'stdout': result.stdout
                }
                
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"R script failed: {e.stderr}")
        except Exception as e:
            raise RuntimeError(f"Error running R script: {str(e)}")
    
    def test_r_environment(self):
        """测试R环境是否可用"""
        try:
            result = subprocess.run(
                ['R', '--version'], 
                capture_output=True, 
                text=True, 
                check=True
            )
            return True, result.stdout
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            return False, str(e)
