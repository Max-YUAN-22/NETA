# NETA项目文件结构

```
NETA/
├── _config.yml                    # Jekyll网站配置文件
├── index.md                       # 网站主页内容
├── README.md                      # 项目说明文档
├── DEPLOYMENT.md                  # 部署指南
├── assets/                        # 静态资源文件夹
│   ├── css/
│   │   └── style.css              # 自定义CSS样式
│   ├── images/                    # 图片资源
│   │   ├── neta-screenshot.png   # 应用截图
│   │   └── logo.png              # 项目logo
│   └── js/                        # JavaScript文件
├── shiny_app/                     # Shiny应用文件夹
│   ├── app.R                      # 主应用文件
│   ├── global.R                   # 全局设置和函数
│   ├── ui.R                       # 用户界面定义
│   ├── server.R                   # 服务器逻辑
│   ├── www/                       # 静态资源
│   │   ├── style.css              # 应用样式
│   │   └── custom.js              # 自定义JavaScript
│   └── data/                      # 应用数据文件
│       ├── expression_matrix.rds # 表达矩阵
│       ├── metadata.rds           # 样本信息
│       └── gene_annotations.rds   # 基因注释
├── R_scripts/                     # R脚本文件夹
│   ├── install_dependencies.R     # 依赖包安装脚本
│   ├── data_processing.R          # 数据处理流程
│   ├── quality_control.R          # 质量控制脚本
│   ├── normalization.R            # 数据标准化脚本
│   ├── batch_correction.R         # 批次校正脚本
│   ├── differential_expression.R  # 差异表达分析
│   ├── survival_analysis.R        # 生存分析脚本
│   ├── pathway_analysis.R         # 通路分析脚本
│   └── visualization.R            # 可视化函数
├── data/                          # 数据文件夹
│   ├── raw/                       # 原始数据
│   │   ├── geo/                   # GEO数据库数据
│   │   ├── tcga/                  # TCGA数据库数据
│   │   └── clinical/              # 临床数据
│   ├── processed/                 # 处理后数据
│   │   ├── expression_matrices/   # 标准化表达矩阵
│   │   ├── metadata/              # 处理后的样本信息
│   │   ├── annotations/           # 基因注释信息
│   │   └── results/               # 分析结果
│   └── external/                  # 外部数据库
│       ├── gene_sets/             # 基因集数据
│       ├── pathways/              # 通路数据
│       └── drug_targets/          # 药物靶点数据
├── docs/                          # 文档文件夹
│   ├── user_guide.md              # 用户使用指南
│   ├── data_description.md        # 数据描述文档
│   ├── analysis_methods.md        # 分析方法说明
│   └── api_reference.md           # API参考文档
├── tests/                         # 测试文件夹
│   ├── test_data_processing.R     # 数据处理测试
│   ├── test_shiny_app.R          # Shiny应用测试
│   └── test_data/                # 测试数据
├── scripts/                       # 部署和维护脚本
│   ├── setup.sh                  # 环境设置脚本
│   ├── deploy.sh                 # 部署脚本
│   ├── update_data.sh            # 数据更新脚本
│   └── backup.sh                 # 备份脚本
├── .gitignore                     # Git忽略文件
├── .Rprofile                     # R配置文件
├── DESCRIPTION                    # R包描述文件
├── NAMESPACE                      # R包命名空间
└── LICENSE                        # 许可证文件
```

## 主要文件说明

### 配置文件
- `_config.yml`: Jekyll网站配置，包含网站标题、描述、主题等设置
- `index.md`: 网站主页内容，使用Markdown格式编写
- `README.md`: 项目说明文档，包含项目介绍、安装和使用方法

### Shiny应用文件
- `app.R`: Shiny应用的主文件，包含UI和server逻辑
- `global.R`: 全局设置，加载包、读取数据、定义全局函数
- `ui.R`: 用户界面定义，使用shinydashboard布局
- `server.R`: 服务器端逻辑，处理用户输入和生成输出

### R脚本文件
- `install_dependencies.R`: 自动安装所需的R包
- `data_processing.R`: 主要的数据处理流程
- `quality_control.R`: 数据质量控制函数
- `normalization.R`: 数据标准化函数
- `differential_expression.R`: 差异表达分析函数
- `survival_analysis.R`: 生存分析函数
- `pathway_analysis.R`: 通路分析函数

### 数据文件夹
- `raw/`: 存储从公共数据库下载的原始数据
- `processed/`: 存储经过质量控制、标准化等处理的数据
- `external/`: 存储外部数据库和参考数据

### 文档文件夹
- `user_guide.md`: 详细的用户使用指南
- `data_description.md`: 数据来源和格式说明
- `analysis_methods.md`: 分析方法的详细说明

## 使用建议

1. **开发环境**: 使用RStudio进行R代码开发和调试
2. **版本控制**: 使用Git进行代码版本管理
3. **数据管理**: 定期备份重要数据文件
4. **文档维护**: 及时更新文档以反映代码变更
5. **测试**: 在部署前进行充分测试
