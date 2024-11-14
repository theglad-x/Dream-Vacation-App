# Use a specific version of Node.js
FROM node:18-alpine

ENV NODE_OPTIONS=--openssl-legacy-provider

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the remaining application code
COPY . .

# Expose the port your app runs on
EXPOSE 3001

# Start the application
CMD ["node", "server.js"]
