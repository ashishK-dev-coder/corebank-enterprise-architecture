import React, { useState } from 'react';
import './index.css';

const API_BASE = 'http://localhost:4000/api';

function App() {
  const [token, setToken] = useState<string | null>(localStorage.getItem('token'));
  
  if (!token) {
    return <Login onLogin={(t) => {
      setToken(t);
      localStorage.setItem('token', t);
    }} />;
  }

  return <Dashboard onLogout={() => {
    setToken(null);
    localStorage.removeItem('token');
  }} token={token} />;
}

function Login({ onLogin }: { onLogin: (token: string) => void }) {
  const [username, setUsername] = useState('admin');
  const [password, setPassword] = useState('password123');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const res = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });

      if (!res.ok) throw new Error('Invalid credentials');
      
      const data = await res.json();
      if (data.token) {
        onLogin(data.token);
      }
    } catch (err: any) {
      setError(err.message || 'Failed to login');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="glass-panel">
      <h1>CoreBank Portal</h1>
      <p className="subtitle">Enter your credentials to access the secure network.</p>
      
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label>Username</label>
          <input 
            type="text" 
            value={username} 
            onChange={(e) => setUsername(e.target.value)}
            required 
          />
        </div>
        <div className="form-group">
          <label>Password</label>
          <input 
            type="password" 
            value={password} 
            onChange={(e) => setPassword(e.target.value)}
            required 
          />
        </div>
        <button type="submit" className="primary-btn" disabled={loading}>
          {loading ? 'Authenticating...' : 'Secure Login'}
        </button>
      </form>
      
      {error && <div className="message-box error">{error}</div>}
    </div>
  );
}

function Dashboard({ onLogout, token }: { onLogout: () => void, token: string }) {
  const [amount, setAmount] = useState('');
  const [destination, setDestination] = useState('DUMMY-100K');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{type: 'success'|'error', text: string} | null>(null);

  const handleTransfer = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setMessage(null);

    try {
      const res = await fetch(`${API_BASE}/transaction/process-transfer`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ 
          amount: parseFloat(amount), 
          destination 
        })
      });

      const data = await res.json();
      
      if (!res.ok) {
        throw new Error(data.detail || 'Transfer failed');
      }

      setMessage({ type: 'success', text: `Transfer successful! Remaining destination balance: ₹${data.remaining_dummy_balance}` });
      setAmount('');
    } catch (err: any) {
      setMessage({ type: 'error', text: err.message || 'Transfer failed' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="glass-panel large">
      <div className="dashboard-header">
        <div>
          <h1>CoreBank Dashboard</h1>
          <p className="subtitle" style={{marginBottom: 0}}>Welcome back, Admin</p>
        </div>
        <button onClick={onLogout}>Sign Out</button>
      </div>

      <div className="dashboard-content">
        <div className="balance-card">
          <h3>Total Balance</h3>
          <div className="amount">₹100,000.00</div>
          <p className="subtitle" style={{marginTop: '0.5rem', marginBottom: 0}}>
            Ready for transfers
          </p>
        </div>

        <div>
          <h3 style={{marginBottom: '1rem'}}>Transfer Funds</h3>
          <form onSubmit={handleTransfer}>
            <div className="form-group">
              <label>Amount (₹)</label>
              <input 
                type="number" 
                min="1"
                step="0.01"
                value={amount} 
                onChange={(e) => setAmount(e.target.value)}
                placeholder="e.g. 5000"
                required 
              />
            </div>
            <div className="form-group">
              <label>Destination Account</label>
              <input 
                type="text" 
                value={destination} 
                onChange={(e) => setDestination(e.target.value)}
                required 
              />
            </div>
            <button type="submit" className="primary-btn" disabled={loading}>
              {loading ? 'Processing...' : 'Initiate Transfer'}
            </button>
          </form>

          {message && (
            <div className={`message-box ${message.type}`}>
              {message.text}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;
