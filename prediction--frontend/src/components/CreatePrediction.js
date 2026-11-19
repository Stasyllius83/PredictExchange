import React, { useState } from 'react';
import { ethers } from 'ethers';

const CreatePrediction = ({ predictExchange, account }) => {
  const [question, setQuestion] = useState('');
  const [oracle, setOracle] = useState('');
  const [predictedPrice, setPredictedPrice] = useState('');
  const [durationDays, setDurationDays] = useState('');
  const [durationHours, setDurationHours] = useState('');
  const [durationMinutes, setDurationMinutes] = useState('');
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState({});

  // Функция для преобразования дней, часов и минут в секунды
  const convertToSeconds = (days, hours, minutes) => {
    const daysNum = parseInt(days) || 0;
    const hoursNum = parseInt(hours) || 0;
    const minutesNum = parseInt(minutes) || 0;
    return (daysNum * 86400) + (hoursNum * 3600) + (minutesNum * 60);
  };

  // Функция для форматирования времени для отображения
  const formatDuration = (days, hours, minutes) => {
    const parts = [];
    if (days > 0) parts.push(`${days} day${days !== 1 ? 's' : ''}`);
    if (hours > 0) parts.push(`${hours} hour${hours !== 1 ? 's' : ''}`);
    if (minutes > 0) parts.push(`${minutes} minute${minutes !== 1 ? 's' : ''}`);
    return parts.join(', ') || '0 minutes';
  };

  const validateForm = () => {
    const newErrors = {};
    
    if (!question.trim()) {
      newErrors.question = "Question is required";
    } else if (question.length > 200) {
      newErrors.question = "Question must be less than 200 characters";
    }
    
    if (!oracle.trim()) {
      newErrors.oracle = "Oracle address is required";
    } else if (!ethers.isAddress(oracle)) {
      newErrors.oracle = "Invalid Ethereum address";
    }
    
    if (!predictedPrice && predictedPrice !== 0) {
      newErrors.predictedPrice = "Predicted price is required";
    } else {
      const price = parseInt(predictedPrice);
      if (isNaN(price)) {
        newErrors.predictedPrice = "Must be a valid integer";
      } else if (price < 0) {
        newErrors.predictedPrice = "Price must be 0 or greater";
      } else if (price > 1000000) {
        newErrors.predictedPrice = "Price cannot exceed 1,000,000 USD";
      } else if (!Number.isInteger(price)) {
        newErrors.predictedPrice = "Price must be an integer (whole number)";
      }
    }
    
    // Проверка длительности
    const days = parseInt(durationDays) || 0;
    const hours = parseInt(durationHours) || 0;
    const minutes = parseInt(durationMinutes) || 0;
    const totalSeconds = convertToSeconds(days, hours, minutes);
    
    if (days === 0 && hours === 0 && minutes === 0) {
      newErrors.duration = "Duration must be greater than 0";
    } else if (totalSeconds > 31536000) { // 1 год в секундах
      newErrors.duration = "Duration cannot exceed 1 year (365 days)";
    } else if (minutes > 59) {
      newErrors.duration = "Minutes cannot exceed 59";
    } else if (hours > 23) {
      newErrors.duration = "Hours cannot exceed 23";
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleCreate = async () => {
    if (!predictExchange) {
      alert("Contract not connected");
      return;
    }
    
    if (!validateForm()) {
      return;
    }
    
    setLoading(true);
    try {
      const predictedPriceValue = parseInt(predictedPrice);
      const durationInSeconds = convertToSeconds(
        durationDays, 
        durationHours, 
        durationMinutes
      );
      
      const tx = await predictExchange.createPrediction(
        question, 
        oracle, 
        predictedPriceValue,
        durationInSeconds
      );
      
      await tx.wait();
      alert("Prediction created successfully!");
      
      // Очищаем форму
      setQuestion('');
      setOracle('');
      setPredictedPrice('');
      setDurationDays('');
      setDurationHours('');
      setDurationMinutes('');
      setErrors({});
      
    } catch (err) {
      console.error("Error creating prediction:", err);
      
      let errorMessage = "Transaction failed: ";
      if (err.reason) {
        errorMessage += err.reason;
      } else if (err.message) {
        if (err.message.includes("NotAdmin")) {
          errorMessage += "You are not an admin";
        } else if (err.message.includes("execution reverted")) {
          errorMessage += "Contract execution reverted. Check parameters.";
        } else {
          errorMessage += err.message;
        }
      } else {
        errorMessage += "Unknown error";
      }
      
      alert(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  // Функция для быстрого выбора предустановленной длительности
  const setPresetDuration = (days, hours, minutes) => {
    setDurationDays(days.toString());
    setDurationHours(hours.toString());
    setDurationMinutes(minutes.toString());
  };

  return (
    <div style={{ 
      border: '1px solid #ccc', 
      padding: '1.5rem', 
      margin: '1rem 0',
      borderRadius: '8px',
      backgroundColor: '#f9f9f9'
    }}>
      <h2 style={{ marginTop: 0 }}>Create Prediction (Admin only)</h2>
      
      <div style={{ marginBottom: '1rem' }}>
        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 'bold' }}>
          Question:
        </label>
        <input 
          type="text"
          style={{ 
            width: '100%', 
            padding: '0.5rem',
            border: errors.question ? '1px solid red' : '1px solid #ccc',
            borderRadius: '4px'
          }}
          value={question}
          onChange={e => setQuestion(e.target.value)}
          placeholder="e.g., ETH price will be less than $5000 by Dec 31, 2024?"
          disabled={loading}
        />
        {errors.question && (
          <small style={{ color: 'red', display: 'block', marginTop: '0.25rem' }}>
            {errors.question}
          </small>
        )}
      </div>
      
      <div style={{ marginBottom: '1rem' }}>
        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 'bold' }}>
          Oracle Address:
        </label>
        <input 
          type="text"
          style={{ 
            width: '100%', 
            padding: '0.5rem',
            border: errors.oracle ? '1px solid red' : '1px solid #ccc',
            borderRadius: '4px'
          }}
          value={oracle}
          onChange={e => setOracle(e.target.value)}
          placeholder="0x..."
          disabled={loading}
        />
        {errors.oracle && (
          <small style={{ color: 'red', display: 'block', marginTop: '0.25rem' }}>
            {errors.oracle}
          </small>
        )}
        <small style={{ color: '#666', display: 'block', marginTop: '0.25rem' }}>
          Address of the oracle that will determine the outcome
        </small>
      </div>
      
      <div style={{ marginBottom: '1rem' }}>
        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 'bold' }}>
          Predicted Price (USD):
        </label>
        <input 
          type="number"
          step="1"
          min="0"
          max="1000000"
          style={{ 
            width: '100%', 
            padding: '0.5rem',
            border: errors.predictedPrice ? '1px solid red' : '1px solid #ccc',
            borderRadius: '4px',
            fontFamily: 'monospace'
          }}
          value={predictedPrice}
          onChange={e => setPredictedPrice(e.target.value)}
          placeholder="e.g., 5000 (whole dollars only)"
          disabled={loading}
        />
        {errors.predictedPrice && (
          <small style={{ color: 'red', display: 'block', marginTop: '0.25rem' }}>
            {errors.predictedPrice}
          </small>
        )}
        <small style={{ color: '#666', display: 'block', marginTop: '0.25rem' }}>
          Target price in whole US dollars (0 to 1,000,000). <strong>No decimals allowed.</strong>
          <br />
          Example: 5000 = $5,000 USD target price
        </small>
      </div>
      
      <div style={{ marginBottom: '1rem' }}>
        <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 'bold' }}>
          Duration:
        </label>
        
        <div style={{ display: 'flex', gap: '15px', flexWrap: 'wrap', marginBottom: '10px' }}>
          <div style={{ flex: 1, minWidth: '100px' }}>
            <input
              type="number"
              step="1"
              min="0"
              max="365"
              value={durationDays}
              onChange={e => setDurationDays(e.target.value)}
              placeholder="Days"
              style={{ 
                width: '100%', 
                padding: '0.5rem',
                border: errors.duration ? '1px solid red' : '1px solid #ccc',
                borderRadius: '4px'
              }}
              disabled={loading}
            />
            <small style={{ color: '#666' }}>Days</small>
          </div>
          
          <div style={{ flex: 1, minWidth: '100px' }}>
            <input
              type="number"
              step="1"
              min="0"
              max="23"
              value={durationHours}
              onChange={e => setDurationHours(e.target.value)}
              placeholder="Hours"
              style={{ 
                width: '100%', 
                padding: '0.5rem',
                border: errors.duration ? '1px solid red' : '1px solid #ccc',
                borderRadius: '4px'
              }}
              disabled={loading}
            />
            <small style={{ color: '#666' }}>Hours</small>
          </div>
          
          <div style={{ flex: 1, minWidth: '100px' }}>
            <input
              type="number"
              step="1"
              min="0"
              max="59"
              value={durationMinutes}
              onChange={e => setDurationMinutes(e.target.value)}
              placeholder="Minutes"
              style={{ 
                width: '100%', 
                padding: '0.5rem',
                border: errors.duration ? '1px solid red' : '1px solid #ccc',
                borderRadius: '4px'
              }}
              disabled={loading}
            />
            <small style={{ color: '#666' }}>Minutes</small>
          </div>
        </div>
        
        {errors.duration && (
          <small style={{ color: 'red', display: 'block', marginTop: '0.25rem' }}>
            {errors.duration}
          </small>
        )}
        
        {/* Предустановленные длительности */}
        <div style={{ marginTop: '10px' }}>
          <small style={{ color: '#666', display: 'block', marginBottom: '5px' }}>
            Quick presets:
          </small>
          <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
            <button
              type="button"
              onClick={() => setPresetDuration(0, 1, 0)}
              style={{
                padding: '4px 8px',
                fontSize: '12px',
                backgroundColor: '#e0e0e0',
                border: 'none',
                borderRadius: '4px',
                cursor: 'pointer'
              }}
            >
              1 hour
            </button>
            <button
              type="button"
              onClick={() => setPresetDuration(0, 24, 0)}
              style={{
                padding: '4px 8px',
                fontSize: '12px',
                backgroundColor: '#e0e0e0',
                border: 'none',
                borderRadius: '4px',
                cursor: 'pointer'
              }}
            >
              1 day
            </button>
            <button
              type="button"
              onClick={() => setPresetDuration(7, 0, 0)}
              style={{
                padding: '4px 8px',
                fontSize: '12px',
                backgroundColor: '#e0e0e0',
                border: 'none',
                borderRadius: '4px',
                cursor: 'pointer'
              }}
            >
              7 days
            </button>
            <button
              type="button"
              onClick={() => setPresetDuration(30, 0, 0)}
              style={{
                padding: '4px 8px',
                fontSize: '12px',
                backgroundColor: '#e0e0e0',
                border: 'none',
                borderRadius: '4px',
                cursor: 'pointer'
              }}
            >
              30 days
            </button>
            <button
              type="button"
              onClick={() => setPresetDuration(90, 0, 0)}
              style={{
                padding: '4px 8px',
                fontSize: '12px',
                backgroundColor: '#e0e0e0',
                border: 'none',
                borderRadius: '4px',
                cursor: 'pointer'
              }}
            >
              90 days
            </button>
          </div>
        </div>
        
        <small style={{ color: '#666', display: 'block', marginTop: '10px' }}>
          Total duration: <strong>
            {formatDuration(
              parseInt(durationDays) || 0,
              parseInt(durationHours) || 0,
              parseInt(durationMinutes) || 0
            )}
          </strong>
          {convertToSeconds(durationDays, durationHours, durationMinutes) > 0 && (
            <> ({convertToSeconds(durationDays, durationHours, durationMinutes).toLocaleString()} seconds)</>
          )}
        </small>
      </div>
      
      <div style={{ 
        backgroundColor: '#e8f5e9', 
        padding: '0.75rem', 
        borderRadius: '4px', 
        marginBottom: '1rem',
        fontSize: '0.9rem'
      }}>
        <strong>Summary:</strong>
        <ul style={{ margin: '0.5rem 0 0 0', paddingLeft: '1.5rem' }}>
          <li>Question: {question || '(not set)'}</li>
          <li>Oracle: {oracle || '(not set)'}</li>
          <li>Predicted Price: {`$${parseInt(predictedPrice).toLocaleString()} USD`}</li>
          <li>Duration: {formatDuration(
              parseInt(durationDays) || 0,
              parseInt(durationHours) || 0,
              parseInt(durationMinutes) || 0
            ) || '(not set)'}
          </li>
          <li>End date: {(() => {
            const totalSeconds = convertToSeconds(durationDays, durationHours, durationMinutes);
            if (totalSeconds > 0) {
              const endDate = new Date(Date.now() + totalSeconds * 1000);
              return endDate.toLocaleString();
            }
            return '(not set)';
          })()}
          </li>
        </ul>
      </div>
      
      <button 
        onClick={handleCreate} 
        disabled={loading}
        style={{
          width: '100%',
          padding: '0.75rem',
          backgroundColor: '#4CAF50',
          color: 'white',
          border: 'none',
          borderRadius: '4px',
          cursor: loading ? 'not-allowed' : 'pointer',
          fontSize: '1rem',
          opacity: loading ? 0.6 : 1
        }}
      >
        {loading ? "Creating..." : "Create Prediction"}
      </button>
    </div>
  );
};

export default CreatePrediction;
