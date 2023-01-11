FROM node:10.13.0-alpine as builder

ENV CI=true

WORKDIR /app
COPY ./ ./

CMD [ "npm", "start" ]

RUN npm ci
RUN npm run build

# production stage
FROM nginx:stable-alpine
WORKDIR /app
# Copy the respective nginx configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=builder ./app/dist/ /app

RUN chown nginx:nginx /app
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]