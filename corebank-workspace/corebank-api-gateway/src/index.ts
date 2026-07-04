import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { createProxyMiddleware } from 'http-proxy-middleware';
import { v4 as uuidv4 } from 'uuid';

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());

// Middleware to inject X-Trace-ID
app.use((req: Request, res: Response, next: NextFunction) => {
    const traceId = uuidv4();
    req.headers['x-trace-id'] = traceId;
    res.setHeader('x-trace-id', traceId);
    next();
});

const IDENTITY_URL = process.env.IDENTITY_URL || 'http://identity-service:5000';
const TRANSACTION_URL = process.env.TRANSACTION_URL || 'http://transaction-engine:8000';

app.use('/api/auth', createProxyMiddleware({
    target: IDENTITY_URL,
    changeOrigin: true,
    pathRewrite: {
        '^/api/auth': '', // Removes /api/auth from the proxied request
    },
    onProxyReq: (proxyReq: any, req: any, res: any) => {
        // Forward the generated trace ID
        if (req.headers['x-trace-id']) {
            proxyReq.setHeader('x-trace-id', req.headers['x-trace-id'] as string);
        }
    }
}));

app.use('/api/transaction', createProxyMiddleware({
    target: TRANSACTION_URL,
    changeOrigin: true,
    pathRewrite: {
        '^/api/transaction': '',
    },
    onProxyReq: (proxyReq: any, req: any, res: any) => {
        if (req.headers['x-trace-id']) {
            proxyReq.setHeader('x-trace-id', req.headers['x-trace-id'] as string);
        }
    }
}));

app.listen(PORT, () => {
    console.log(`API Gateway is running on port ${PORT}`);
});
