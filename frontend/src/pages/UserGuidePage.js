import React from 'react';
import { Container, Row, Col, Card, Accordion, Badge } from 'react-bootstrap';

const UserGuidePage = () => {
  return (
    <Container className="py-5">
      <div className="text-center mb-5">
        <h1 className="display-4 fw-bold mb-3">📖 用户指南</h1>
        <p className="lead text-muted">
          详细的使用说明和功能介绍，帮助您快速上手NETA平台
        </p>
      </div>

      <Row className="g-4">
        {/* 快速开始 */}
        <Col lg={6}>
          <Card className="h-100 shadow-sm">
            <Card.Header className="bg-primary text-white">
              <h5 className="mb-0">🚀 快速开始</h5>
            </Card.Header>
            <Card.Body>
              <Accordion>
                <Accordion.Item eventKey="0">
                  <Accordion.Header>
                    <i className="bi bi-1-circle me-2"></i>访问平台
                  </Accordion.Header>
                  <Accordion.Body>
                    <p>直接访问 <a href="https://max-yuan-22.github.io/NETA/" target="_blank" rel="noopener noreferrer">NETA平台</a> 开始使用。</p>
                    <p>无需注册，无需安装，打开浏览器即可使用。</p>
                  </Accordion.Body>
                </Accordion.Item>
                
                <Accordion.Item eventKey="1">
                  <Accordion.Header>
                    <i className="bi bi-2-circle me-2"></i>浏览数据集
                  </Accordion.Header>
                  <Accordion.Body>
                    <p>在"数据集"页面查看所有可用的GEO数据集：</p>
                    <ul>
                      <li>19个真实GEO数据集</li>
                      <li>按组织类型筛选</li>
                      <li>按肿瘤类型筛选</li>
                      <li>查看详细统计信息</li>
                    </ul>
                  </Accordion.Body>
                </Accordion.Item>
                
                <Accordion.Item eventKey="2">
                  <Accordion.Header>
                    <i className="bi bi-3-circle me-2"></i>开始分析
                  </Accordion.Header>
                  <Accordion.Body>
                    <p>选择您需要的分析功能：</p>
                    <ul>
                      <li>基因查询 - 查看特定基因表达</li>
                      <li>PCA分析 - 主成分分析</li>
                      <li>火山图 - 差异表达可视化</li>
                      <li>热图 - 聚类分析</li>
                    </ul>
                  </Accordion.Body>
                </Accordion.Item>
              </Accordion>
            </Card.Body>
          </Card>
        </Col>

        {/* 功能详解 */}
        <Col lg={6}>
          <Card className="h-100 shadow-sm">
            <Card.Header className="bg-success text-white">
              <h5 className="mb-0">🔬 功能详解</h5>
            </Card.Header>
            <Card.Body>
              <Accordion>
                <Accordion.Item eventKey="0">
                  <Accordion.Header>
                    <i className="bi bi-search me-2"></i>基因查询
                  </Accordion.Header>
                  <Accordion.Body>
                    <p><strong>功能：</strong>查询特定基因在不同数据集中的表达情况</p>
                    <p><strong>使用方法：</strong></p>
                    <ol>
                      <li>输入基因符号（如：TP53, MYC, EGFR）</li>
                      <li>选择数据集或使用所有数据集</li>
                      <li>点击"查询"按钮</li>
                      <li>查看表达量分布图表</li>
                    </ol>
                  </Accordion.Body>
                </Accordion.Item>
                
                <Accordion.Item eventKey="1">
                  <Accordion.Header>
                    <i className="bi bi-graph-up me-2"></i>PCA分析
                  </Accordion.Header>
                  <Accordion.Body>
                    <p><strong>功能：</strong>主成分分析，降维可视化样本分布</p>
                    <p><strong>使用方法：</strong></p>
                    <ol>
                      <li>选择数据集</li>
                      <li>选择主成分数量（默认前2个）</li>
                      <li>点击"运行分析"</li>
                      <li>查看PCA散点图</li>
                    </ol>
                  </Accordion.Body>
                </Accordion.Item>
                
                <Accordion.Item eventKey="2">
                  <Accordion.Header>
                    <i className="bi bi-graph-up-arrow me-2"></i>火山图
                  </Accordion.Header>
                  <Accordion.Header>
                    <p><strong>功能：</strong>可视化差异表达分析结果</p>
                    <p><strong>使用方法：</strong></p>
                    <ol>
                      <li>选择数据集和比较组</li>
                      <li>设置显著性阈值</li>
                      <li>运行差异表达分析</li>
                      <li>查看火山图结果</li>
                    </ol>
                  </Accordion.Header>
                </Accordion.Item>
              </Accordion>
            </Card.Body>
          </Card>
        </Col>

        {/* 数据说明 */}
        <Col lg={6}>
          <Card className="h-100 shadow-sm">
            <Card.Header className="bg-info text-white">
              <h5 className="mb-0">📊 数据说明</h5>
            </Card.Header>
            <Card.Body>
              <div className="mb-3">
                <h6>数据来源</h6>
                <p className="text-muted">所有数据均来自NCBI的GEO数据库，100%真实数据。</p>
              </div>
              
              <div className="mb-3">
                <h6>数据规模</h6>
                <Row>
                  <Col xs={6}>
                    <div className="text-center">
                      <Badge bg="primary" className="fs-6">19</Badge>
                      <div className="small text-muted">数据集</div>
                    </div>
                  </Col>
                  <Col xs={6}>
                    <div className="text-center">
                      <Badge bg="success" className="fs-6">2,196</Badge>
                      <div className="small text-muted">样本</div>
                    </div>
                  </Col>
                  <Col xs={6}>
                    <div className="text-center">
                      <Badge bg="warning" className="fs-6">230K</Badge>
                      <div className="small text-muted">基因</div>
                    </div>
                  </Col>
                  <Col xs={6}>
                    <div className="text-center">
                      <Badge bg="info" className="fs-6">3.8M</Badge>
                      <div className="small text-muted">表达记录</div>
                    </div>
                  </Col>
                </Row>
              </div>
              
              <div className="mb-3">
                <h6>组织类型</h6>
                <div className="d-flex flex-wrap gap-1">
                  <Badge bg="outline-primary">胰腺 (8个)</Badge>
                  <Badge bg="outline-success">前列腺 (4个)</Badge>
                  <Badge bg="outline-warning">胃肠道 (4个)</Badge>
                  <Badge bg="outline-info">肺 (3个)</Badge>
                </div>
              </div>
            </Card.Body>
          </Card>
        </Col>

        {/* 常见问题 */}
        <Col lg={6}>
          <Card className="h-100 shadow-sm">
            <Card.Header className="bg-warning text-white">
              <h5 className="mb-0">❓ 常见问题</h5>
            </Card.Header>
            <Card.Body>
              <Accordion>
                <Accordion.Item eventKey="0">
                  <Accordion.Header>
                    <i className="bi bi-question-circle me-2"></i>如何选择合适的基因符号？
                  </Accordion.Header>
                  <Accordion.Body>
                    <p>建议使用标准的HUGO基因符号，如：</p>
                    <ul>
                      <li>TP53 (p53肿瘤抑制因子)</li>
                      <li>MYC (c-Myc原癌基因)</li>
                      <li>EGFR (表皮生长因子受体)</li>
                      <li>BRCA1 (乳腺癌易感基因1)</li>
                    </ul>
                  </Accordion.Body>
                </Accordion.Item>
                
                <Accordion.Item eventKey="1">
                  <Accordion.Header>
                    <i className="bi bi-question-circle me-2"></i>分析结果如何解释？
                  </Accordion.Header>
                  <Accordion.Body>
                    <p>不同分析结果的解释：</p>
                    <ul>
                      <li><strong>PCA图：</strong>点代表样本，距离近的样本相似性高</li>
                      <li><strong>火山图：</strong>红点表示显著差异表达基因</li>
                      <li><strong>热图：</strong>颜色深浅表示表达量高低</li>
                    </ul>
                  </Accordion.Body>
                </Accordion.Item>
                
                <Accordion.Item eventKey="2">
                  <Accordion.Header>
                    <i className="bi bi-question-circle me-2"></i>数据可以下载吗？
                  </Accordion.Header>
                  <Accordion.Body>
                    <p>目前平台主要提供在线分析功能，原始数据可以从GEO数据库下载。</p>
                    <p>分析结果可以通过截图或复制数据的方式保存。</p>
                  </Accordion.Body>
                </Accordion.Item>
              </Accordion>
            </Card.Body>
          </Card>
        </Col>

        {/* 技术支持 */}
        <Col lg={12}>
          <Card className="shadow-sm">
            <Card.Header className="bg-dark text-white">
              <h5 className="mb-0">🛠️ 技术支持</h5>
            </Card.Header>
            <Card.Body>
              <Row>
                <Col md={4}>
                  <div className="text-center">
                    <i className="bi bi-github display-4 text-primary mb-3"></i>
                    <h6>GitHub</h6>
                    <p className="text-muted">查看源代码和提交问题</p>
                    <a href="https://github.com/Max-YUAN-22/NETA" target="_blank" rel="noopener noreferrer" className="btn btn-outline-primary btn-sm">
                      访问仓库
                    </a>
                  </div>
                </Col>
                <Col md={4}>
                  <div className="text-center">
                    <i className="bi bi-book display-4 text-success mb-3"></i>
                    <h6>文档</h6>
                    <p className="text-muted">详细的技术文档</p>
                    <a href="https://github.com/Max-YUAN-22/NETA/blob/main/README.md" target="_blank" rel="noopener noreferrer" className="btn btn-outline-success btn-sm">
                      查看文档
                    </a>
                  </div>
                </Col>
                <Col md={4}>
                  <div className="text-center">
                    <i className="bi bi-envelope display-4 text-info mb-3"></i>
                    <h6>联系</h6>
                    <p className="text-muted">获取技术支持</p>
                    <a href="mailto:max-yuan-22@github.com" className="btn btn-outline-info btn-sm">
                      发送邮件
                    </a>
                  </div>
                </Col>
              </Row>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
};

export default UserGuidePage;
