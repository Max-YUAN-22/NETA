import React from 'react';
import { Spinner } from 'react-bootstrap';

const LoadingSpinner = ({ message = "加载中...", size = "sm" }) => {
  return (
    <div className="text-center py-4">
      <Spinner animation="border" size={size} role="status">
        <span className="visually-hidden">{message}</span>
      </Spinner>
      <div className="mt-2 text-muted">{message}</div>
    </div>
  );
};

export default LoadingSpinner;
