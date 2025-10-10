import React from 'react';
import { Alert, Button } from 'react-bootstrap';

const ErrorAlert = ({ error, onRetry, onDismiss }) => {
  return (
    <Alert variant="danger" dismissible onClose={onDismiss}>
      <Alert.Heading>出现错误</Alert.Heading>
      <p>{error}</p>
      {onRetry && (
        <Button variant="outline-danger" onClick={onRetry}>
          重试
        </Button>
      )}
    </Alert>
  );
};

export default ErrorAlert;
