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
            if(response.statusCode !== 200){
				reject(response.statusCode);
            }
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

function filterAsync(array, predicate) {
    // Take a copy of the array, it might mutate by the time we've finished
   const data = Array.from(array);
   // Transform all the elements into an array of promises using the predicate
   // as the promise
   return Promise.all(data.map((element, index) => predicate(element, index, data)))
   // Use the result of the promises to call the underlying sync filter function
     .then(result => {
       return data.filter((element, index) => {
         return result[index];
       });
     });
 }
(async()=>{
const output = [];
var args = process.argv.slice(2);
await Promise.all(args.map(async function (file) {
  let inputs = require(`../assets/dict/${file}`);
  for(let i = 0; i < inputs.length; ++i) {
    let vocabulary = inputs[i];
    vocabulary.heteronyms = await filterAsync(vocabulary.heteronyms, async function (heteronym) {
        let aid = heteronym.audio_id?heteronym.audio_id:heteronym.id;
        aid = aid.padStart(5, "0");
        let url = `http://t.moedict.tw/${aid}.ogg`;
        console.log(url);
        try {
            let response_body = await getPromise(url);
            //console.log(response_body);
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
  };
}));

const json = JSON.stringify(output, null, 2);
fs.writeFileSync('../assets/dict/output.json', json, 'utf8');
process.exit();
})();