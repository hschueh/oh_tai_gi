// Remove the vocabulary that audio id doesn't exist.
// {
//     "title": {title},
//     "heteronyms": [
//       {
//         "id": {id},
//         "audio_id": {aid, optional},
//         {...},
//       }
//     ]
//   },
//

const fs = require('fs');
const path = require('path');
const http = require('http');


function getPromise(url) {
	return new Promise((resolve, reject) => {
		http.get(url, (response) => {
			let chunks_of_data = [];

			response.on('data', (fragments) => {
				chunks_of_data.push(fragments);
			});

			response.on('end', () => {
				let response_body = Buffer.concat(chunks_of_data);
				resolve(response_body.toString());
			});

			response.on('error', (error) => {
				reject(error);
			});
		});
	});
}

const output = [];
var args = process.argv.slice(2);
args.forEach(function (file) {
  let inputs = require(`../assets/dict/${file}`);
  inputs.forEach(function (vocabulary) {
    vocabulary.heteronyms = vocabulary.heteronyms.filter(async function (heteronym) {
        let aid = heteronym.audio_id?heteronym.audio_id:heteronym.id;
        aid = aid.padStart(5, "0");
        let url = `http://t.moedict.tw/${aid}.ogg`;
        try {
            let response_body = await getPromise(url);
            // console.log(response_body);
            return true;
        }
        catch(error) {
            // Promise rejected
            console.log(`${vocabulary.title}'s ${aid} not available.`);
            return false;
        }
    });
    if(vocabulary.heteronyms.length > 0)
        output.push(vocabulary);
  });
});

const json = JSON.stringify(output, null, 2);
fs.writeFileSync('../assets/dict/output.json', json, 'utf8');
process.exit();