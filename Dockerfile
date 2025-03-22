# # Build stage
# FROM node:20-alpine AS build
# WORKDIR /app
# COPY package*.json ./
# RUN npm ci
# COPY . .
# RUN npm run build

# # Production stage
# FROM nginx:alpine
# COPY --from=build /app/dist /usr/share/nginx/html
# # Add nginx configuration if needed
# # COPY nginx.conf /etc/nginx/conf.d/default.conf
# EXPOSE 80
# CMD ["nginx", "-g", "daemon off;"]


# Build stage
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage - use a specific version and update packages
FROM nginx:1.25-alpine
# Update all packages to latest versions to fix vulnerabilities
RUN apk update && \
    apk upgrade && \
    # Explicitly update the vulnerable libraries
    apk add --no-cache libexpat>=2.7.0-r0 libxml2>=2.13.4-r5 libxslt>=1.1.42-r2 && \
    # Clean up to reduce image size
    rm -rf /var/cache/apk/*

# Copy built app from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Add security-related headers to nginx
RUN echo 'server_tokens off;' > /etc/nginx/conf.d/security.conf

# Create a non-root user to run nginx
RUN adduser -D -H -u 1001 -s /sbin/nologin nginxuser && \
    chown -R nginxuser:nginxuser /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d

# Switch to non-root user
USER nginxuser

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
