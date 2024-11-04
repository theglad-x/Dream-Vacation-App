# Build the image using Node.js
FROM node:18-alpine as build

# Set the environmental variable
ENV NODE_OPTIONS=--openssl-legacy-provider

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the remaining files
COPY . .

# Build the project
RUN npm run build

# Use Nginx to serve the built application
FROM nginx:mainline-alpine

# Copy the build folder from the Node.js build stage to Nginx's default HTML directory
COPY --from=build /app/build /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]