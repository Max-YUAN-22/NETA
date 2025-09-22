# NETA数据搜索指南
# 神经内分泌肿瘤Bulk-RNA-seq数据收集策略

## 搜索策略

### 1. GEO数据库搜索关键词

#### 主要关键词组合
```
"neuroendocrine tumor" AND "RNA-seq" AND "counts"
"pancreatic neuroendocrine" AND "RNA-seq" AND "HTSeq"
"small cell lung cancer" AND "RNA-seq" AND "raw counts"
"carcinoid tumor" AND "RNA-seq" AND "counts matrix"
"GEP-NET" AND "RNA-seq" AND "counts"
"neuroendocrine carcinoma" AND "RNA-seq" AND "HTSeq"
```

#### 具体肿瘤类型关键词
```
# 胰腺神经内分泌肿瘤
"pancreatic neuroendocrine tumor" OR "pancreatic NET" OR "pNET"
"pancreatic neuroendocrine neoplasm" OR "pancreatic NEN"

# 肺神经内分泌肿瘤  
"small cell lung cancer" OR "SCLC"
"large cell neuroendocrine carcinoma" OR "LCNEC"
"atypical carcinoid" OR "typical carcinoid"

# 胃肠道神经内分泌肿瘤
"gastrointestinal neuroendocrine tumor" OR "GI-NET"
"gastroenteropancreatic neuroendocrine tumor" OR "GEP-NET"
"small intestine neuroendocrine tumor"
"rectal neuroendocrine tumor"

# 其他神经内分泌肿瘤
"pheochromocytoma" OR "paraganglioma"
"Merkel cell carcinoma"
"medullary thyroid carcinoma"
```

### 2. 搜索条件筛选

#### 必须满足的条件
- ✅ 数据类型: "Expression profiling by high throughput sequencing"
- ✅ 样本数量: ≥6个样本（每组≥3个生物学重复）
- ✅ 数据格式: Raw counts（原始计数）
- ✅ 样本类型: 野生型（无基因干预）
- ✅ 平台类型: RNA-seq平台

#### 排除条件
- ❌ 包含CRISPR敲除样本
- ❌ 包含基因过表达样本  
- ❌ 包含siRNA/shRNA敲降样本
- ❌ 已标准化的数据（FPKM/RPKM/TPM）
- ❌ 单细胞RNA-seq数据
- ❌ 样本数量<6个

### 3. 已知数据集列表

#### 胰腺神经内分泌肿瘤
```
GSE73338 - Pancreatic neuroendocrine tumors RNA-seq analysis
GSE98894 - Pancreatic neuroendocrine neoplasms comprehensive analysis
GSE117851 - Pancreatic NET subtypes and progression
GSE156405 - Pancreatic NET molecular subtypes
```

#### 肺神经内分泌肿瘤
```
GSE103174 - Small cell lung cancer transcriptome analysis
GSE11969 - Lung neuroendocrine tumors comprehensive study
GSE60436 - SCLC cell lines RNA-seq analysis
GSE126030 - Lung neuroendocrine carcinoma subtypes
```

#### 胃肠道神经内分泌肿瘤
```
GSE98894 - Gastrointestinal neuroendocrine neoplasms
GSE117851 - GEP-NET molecular characterization
GSE156405 - GI-NET progression and metastasis
```

### 4. 数据验证检查清单

#### 下载前验证
- [ ] 检查数据集描述是否包含"RNA-seq"
- [ ] 确认平台类型为RNA-seq相关
- [ ] 验证样本数量≥6个
- [ ] 检查样本描述不包含干预信息
- [ ] 确认数据类型为"Expression profiling by high throughput sequencing"

#### 下载后验证
- [ ] 表达矩阵包含整数值
- [ ] 无负值存在
- [ ] 样本数量符合预期
- [ ] 基因数量合理（>10000个基因）
- [ ] 样本总计数范围合理（>100万reads）

### 5. 搜索工具和方法

#### GEO数据库搜索
1. 访问 https://www.ncbi.nlm.nih.gov/geo/
2. 使用高级搜索功能
3. 设置筛选条件：
   - Data Set Type: "Expression profiling by high throughput sequencing"
   - Organism: "Homo sapiens"
   - Platform: 包含"RNA-seq"或"sequencing"

#### SRA数据库搜索
1. 访问 https://www.ncbi.nlm.nih.gov/sra
2. 搜索关键词组合
3. 筛选条件：
   - Library Strategy: "RNA-Seq"
   - Library Source: "TRANSCRIPTOMIC"
   - Platform: "ILLUMINA"

#### ArrayExpress搜索
1. 访问 https://www.ebi.ac.uk/arrayexpress/
2. 使用关键词搜索
3. 筛选条件：
   - Experiment Type: "RNA-seq"
   - Organism: "Homo sapiens"

### 6. 数据质量评估标准

#### 基本质量指标
- 样本数量: ≥6个（推荐≥10个）
- 基因数量: ≥15000个
- 总计数: ≥100万reads/样本
- 检测基因: ≥5000个基因/样本
- 零值比例: <80%

#### 数据完整性检查
- 表达矩阵完整性
- 样本信息完整性
- 基因注释完整性
- 临床信息完整性

### 7. 数据预处理要求

#### 必须保留的原始信息
- 原始计数矩阵
- 样本标识符
- 基因标识符
- 临床信息
- 实验设计信息

#### 可以标准化的信息
- 基因名称统一
- 样本名称统一
- 临床变量编码统一

### 8. 常见问题和解决方案

#### 问题1: 找不到符合条件的数据集
**解决方案:**
- 扩大搜索关键词范围
- 降低样本数量要求
- 考虑包含相关肿瘤类型

#### 问题2: 数据格式不符合要求
**解决方案:**
- 联系数据提交者获取原始数据
- 查找相关补充材料
- 考虑使用其他数据库

#### 问题3: 样本信息不完整
**解决方案:**
- 查找相关文献获取详细信息
- 联系原作者获取补充信息
- 使用公开的临床数据库补充信息

### 9. 数据使用注意事项

#### 伦理和法律要求
- 遵守数据使用协议
- 引用原始数据来源
- 尊重数据提交者的权利

#### 技术注意事项
- 注意批次效应
- 考虑平台差异
- 验证数据质量

### 10. 推荐的数据收集流程

1. **文献调研** - 查找相关研究论文
2. **数据库搜索** - 使用多种关键词搜索
3. **数据验证** - 检查数据质量和格式
4. **下载数据** - 获取原始数据文件
5. **质量评估** - 进行全面的质量检查
6. **数据整理** - 统一数据格式和注释
7. **文档记录** - 记录数据来源和处理过程

## 使用示例

```r
# 加载搜索脚本
source("R_scripts/data_collection.R")
source("R_scripts/known_datasets.R")

# 开始数据收集
datasets <- collect_neta_data()

# 处理已知数据集
known_datasets <- process_known_datasets()

# 创建数据清单
inventory <- create_data_inventory()
```

## 联系和支持

如果在数据收集过程中遇到问题，请：
1. 查看错误日志
2. 检查网络连接
3. 验证数据访问权限
4. 联系技术支持
