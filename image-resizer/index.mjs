const handler = () => {
    console.log("The Lambda is triggered using github actions");
    return {
        statusCode: 200,
        body: "The Lambda is triggered using github actions"
    };
};

exports.handler = handler;