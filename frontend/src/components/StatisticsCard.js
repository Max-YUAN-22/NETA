import React from 'react';
import { Card } from 'react-bootstrap';

const StatisticsCard = ({ title, value, subtitle, icon, color = "primary", trend = null }) => {
  const getColorClass = () => {
    const colorMap = {
      primary: "text-primary",
      success: "text-success",
      warning: "text-warning",
      info: "text-info",
      danger: "text-danger"
    };
    return colorMap[color] || "text-primary";
  };

  return (
    <Card className="h-100 shadow-sm">
      <Card.Body className="text-center">
        <div className={`display-4 ${getColorClass()}`}>
          {icon}
        </div>
        <Card.Title className="mt-2 mb-1">
          <span className="display-6 fw-bold">{value}</span>
        </Card.Title>
        <Card.Text className="text-muted mb-0">{title}</Card.Text>
        {subtitle && (
          <Card.Text className="text-muted small">{subtitle}</Card.Text>
        )}
        {trend && (
          <div className={`mt-2 small ${trend > 0 ? 'text-success' : 'text-danger'}`}>
            <i className={`bi bi-arrow-${trend > 0 ? 'up' : 'down'}`}></i>
            {Math.abs(trend)}%
          </div>
        )}
      </Card.Body>
    </Card>
  );
};

export default StatisticsCard;
