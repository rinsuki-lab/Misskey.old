FROM node:4.9.1

WORKDIR /usr/src/app
COPY package.json ./
RUN npm install

COPY gulpfile.ls ./
COPY src ./src
RUN npm run build

CMD ["node", "/usr/src/app/lib"]