import React from 'react';
import { Card } from 'react-bootstrap';

const FeatureCard = ({ icon, title, description, features = [], color = "primary" }) => {
  const getColorClass = () => {
    const colorMap = {
      primary: "border-primary",
      success: "border-success",
      warning: "border-warning",
      info: "border-info",
      danger: "border-danger"
    };
    return colorMap[color] || "border-primary";
  };

  return (
    <Card className={`h-100 shadow-sm ${getColorClass()}`}>
      <Card.Header className="bg-transparent border-0 text-center">
        <div className="display-4 text-primary mb-2">{icon}</div>
        <Card.Title className="h5 mb-0">{title}</Card.Title>
      </Card.Header>
      <Card.Body>
        <Card.Text className="text-muted mb-3">{description}</Card.Text>
        {features.length > 0 && (
          <ul className="list-unstyled mb-0">
            {features.map((feature, index) => (
              <li key={index} className="mb-1">
                <i className="bi bi-check-circle-fill text-success me-2"></i>
                <small>{feature}</small>
              </li>
            ))}
          </ul>
        )}
      </Card.Body>
    </Card>
  );
};

export default FeatureCard;
