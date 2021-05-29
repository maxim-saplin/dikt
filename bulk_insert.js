function bulkInsert(db, keys, values) {
  return new Promise((resolve, reject) => {
    let result;
    const tx = db.transaction(["box"], "readwrite");
    tx.oncomplete = function() { 
      resolve(result);
    };
    tx.onerror = function(event) { 
      reject(event.target.error);
    }
    const store = tx.objectStore("box");
    for (var i = 0; i < keys.length; i++)
    {
      const request = store.put(values[i].buffer, keys[i]);
      if (i == keys.length-1) {
        request.onsuccess = function() {
           result = request.result;
        }
      }
    }

  });
}

function testArrays(keys, values) {
  console.log(keys);
  console.log(values);
}