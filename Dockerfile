FROM nginx:alpine


RUN rm -rf /usr/share/nginx/html/*


COPY dist/ /usr/share/nginx/html


EXPOSE 3000


RUN sed -i 's/listen       80;/listen       3000;/g' /etc/nginx/conf.d/default.conf

CMD ["nginx", "-g", "daemon off;"]