import { useState, useEffect } from 'react';
import PredictionDetail from './PredictionDetail';

const PredictionList = ({ predictExchange, conditionalTokens, usdc, account, signer, isAdmin }) => {
  const [questions, setQuestions] = useState([]);
  const [selectedQuestion, setSelectedQuestion] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const fetchQuestions = async () => {
      if (!predictExchange) return;
      setLoading(true);
      try {
        const all = await predictExchange.getAllQuestions();
        setQuestions(all);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchQuestions();
  }, [predictExchange]);

  const selectQuestion = (q) => {
    setSelectedQuestion(q);
  };

  return (
    <div>
      <h2>Existing Predictions</h2>
      {loading && <p>Loading...</p>}
      <ul>
        {questions.map((q, idx) => (
          <li key={idx} onClick={() => selectQuestion(q)} style={{ cursor: 'pointer', margin: '5px 0' }}>
            {q}
          </li>
        ))}
      </ul>
      {selectedQuestion && (
        <PredictionDetail
          question={selectedQuestion}
          predictExchange={predictExchange}
          conditionalTokens={conditionalTokens}
          usdc={usdc}
          account={account}
          signer={signer}
          onClose={() => setSelectedQuestion(null)}
          isAdmin={isAdmin}
        />
      )}
    </div>
  );
};

export default PredictionList;