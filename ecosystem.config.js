module.exports = {
  apps: [
    {
      name: 'cambiatus-backend',
      script: '/opt/cambiatus/backend/current/start_with_env.sh',
      interpreter: 'none',
      cwd: '/opt/cambiatus/backend/current',
      
      // Environment variables for production
      env: {
        MIX_ENV: 'prod',
        PHX_SERVER: 'true',
        PORT: '4000'
      },
      
      // PM2 options
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      
      // Logging - using PM2 defaults
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      
      // Health check
      min_uptime: '10s',
      max_restarts: 10
    }
  ]
};
