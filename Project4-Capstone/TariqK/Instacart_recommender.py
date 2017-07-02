#Capstone - Instacart marketing basket analysis
#Collabourative filtering
#Item - item filtering

import psycopg2
import pandas as pd
import graphlab
from scipy.spatial.distance import cosine

try:
    conn = psycopg2.connect("dbname='Capstone' user='postgres' host='localhost' password='annie123'")
except:
    print "Unable to connect"

cur=conn.cursor()
cur.execute("SELECT * FROM aisle;")
rows=cur.fetchall()

# store as data frame
rows=pd.DataFrame(rows)

# to see the total number of tables in the schema
cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")

# to see how to make a matrix for us to work with.
# The important one is "orders_product_prior" which is connected to table "order"
cur.execute("SELECT * FROM orders_product_prior LIMIT 500;")
opp=pd.DataFrame(cur.fetchall(),columns=["order_id","product_id","add_to_chart","reordered"])

# TODO: get info in ascending order.
cur.execute("SELECT * FROM orders ORDER BY order_id ASC LIMIT 500;")
orders=pd.DataFrame(cur.fetchall(),columns=["order_id","user_id","eval_set","order_num", "order_dow","order_hour_of_day","days_since_prior_order"])

# Incase I want to over efficient and try to change product i to product names
# Otherwise this is an unnecessary step.
cur.execute("SELECT * FROM products LIMIT 500;")
products=pd.DataFrame(cur.fetchall(),columns=["product_id","product_name","aisle_id","department_id"])

# Trial 1a: Just run the opp data with graphlab and see what the result looks like.
# Trial 1b: Run target as 'product_id'
# Trial 2: Make a proper dataset and then run graphlab

#Trial 1a:
opp_data=graphlab.SFrame(opp)
popularity_model=graphlab.popularity_recommender.create(opp_data, user_id='order_id', item_id='product_id',target='reordered')
#Get recommendations for first 5 users and print them
#users = range(1,6) specifies user ID of first 5 users
#k=5 specifies top 5 recommendations to be given
popularity_recomm = popularity_model.recommend(users=range(1,6),k=5)
popularity_recomm.print_rows(num_rows=25)

# Pearson's collabourative filtering
item_sim_model = graphlab.item_similarity_recommender.create(opp_data, user_id='order_id', item_id='product_id',target='reordered', similarity_type='pearson')
item_sim_recomm = item_sim_model.recommend()
item_sim_recomm.print_rows()

# Jaccard filtering
j_item_sim_model = graphlab.item_similarity_recommender.create(opp_data, user_id='order_id', item_id='product_id',target='reordered', similarity_type='jaccard')
j_item_sim_recomm = j_item_sim_model.recommend()
j_item_sim_recomm.print_rows()

#cosine filtering
c_item_sim_model = graphlab.item_similarity_recommender.create(opp_data, user_id='order_id', item_id='product_id',target='reordered', similarity_type='cosine')
c_item_sim_recomm = c_item_sim_model.recommend()
c_item_sim_recomm.print_rows()

# cosine and jaccard show the same output while peason and popularity show the same.
# rerunning it with a bigger data set shows that cosine and jaccard are the same but pearson and popularity recommend different items.

#Trial 1b:
popularity_model_1b=graphlab.popularity_recommender.create(opp_data,user_id='product_id',item_id='order_id',target='reordered')
popularity_recomm_1b = popularity_model_1b.recommend()
popularity_recomm_1b.print_rows()
# this showed me some crazy results but definately interesting.
# Turns out that this determines similarity of item with user(order_id)
# This is intersting because this can show users that are interested in a item.

#Trial 2: Generate dataset similar to http://www.salemmarafi.com/code/collaborative-filtering-with-python/
# TODO: See if you make a dataset with user_id, order_id, product_id and run that through Trial 1 again.
colNames=opp.product_id
#need unique order_id
rowNames=opp.order_id.unique()
new=pd.DataFrame(index=rowNames,columns=colNames)

for i in range(0,opp.index.size):
    print opp.iloc[i,1]
    value=opp.iloc[i,1]
    for j in range(0,new.columns.size):
        if(value==new.columns[j]):
            print opp.iloc[i,0]
            value2=opp.iloc[i,0]
            idx=new.index.get_loc(value2)
    new.iloc[idx][value]=1
#turn NaNs to zero.

new=new.fillna(0)

data_ibs = pd.DataFrame(index=new.columns,columns=new.columns)
for i in range(0,len(data_ibs.columns)) :
    # Loop through the columns for each column
    print i
    for j in range(0,len(data_ibs.columns)) :
        print j
      # Fill in placeholder with cosine similarities
        print 1-cosine(new.iloc[:,i],new.iloc[:,j])
        data_ibs.iloc[i,j] = 1-cosine(new.iloc[:,i],new.iloc[:,j])

data_neighbours = pd.DataFrame(index=data_ibs.columns,columns=range(1,11))

# Loop through our similarity dataframe and fill in neighbouring item names
for i in range(0,len(data_ibs.columns)):
    data_neighbours.iloc[i,:10] = data_ibs.iloc[0:,i].sort_values(ascending=False)[:10].index

data_neighbours.head(6).iloc[:6,2:4]
# The table shows items that are the most similar!

# Now user-item filtering

def getScore(history, similarities):
   return sum(history*similarities)/sum(similarities)

data_sims = pd.DataFrame(index=new.index,columns=new.columns)

#data_sims.iloc[:,:1] = new.iloc[:,:1]
for i in range(0,len(data_sims.index)):
    for j in range(0,len(data_sims.columns)):
        print i,j
        user = data_sims.index[i]
        product = data_sims.columns[j]
        print user, product
        if new.iloc[i,j] == 1:
            print 1
            data_sims.iloc[i,j] = 0
        else:
            print 0
            product_top_names = data_neighbours.ix[product][1:10]
            product_top_sims = data_ibs.ix[product].sort_index(ascending=False)[1:10]
            user_purchases = new.ix[user,product_top_names.iloc[0,:].drop_duplicates(keep='first')]
            data_sims.iloc[i,j] = getScore(user_purchases,product_top_sims)

# Get the top items
data_recommend = pd.DataFrame(index=data_sims.index, columns=['1','2','3','4','5','6'])
#data_recommend.ix[0:,0] = data_sims.iloc[:,0]

# Instead of top item scores, we want to see names
for i in range(0,len(data_sims.index)):
    data_recommend.iloc[i,:] = data_sims.iloc[i,:].sort_values(ascending=False).iloc[1:7,].index.transpose()

# Print a sample
print data_recommend.ix[:,:4]

# Result seems better. Seems to follow the basic principle. Add more data to see what happens
# TODO: Apply regression
