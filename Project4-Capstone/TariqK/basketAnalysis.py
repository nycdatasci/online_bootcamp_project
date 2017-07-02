## This is to explore and analize the data and answer some business questions
# TODO: Make graphs pretty!
import psycopg2
import pandas as pd
import graphlab
from scipy.spatial.distance import cosine
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

try:
    conn = psycopg2.connect("dbname='Capstone' user='postgres' host='localhost' password='annie123'")
except:
    print "Unable to connect"

cur.execute("SELECT * FROM orders_product_prior;")
opp=pd.DataFrame(cur.fetchall(),columns=["order_id","product_id","add_to_chart","reordered"])

cur.execute("SELECT * FROM orders ORDER BY order_id ASC;")
orders=pd.DataFrame(cur.fetchall(),columns=["order_id","user_id","eval_set","order_num", "order_dow","order_hour_of_day","days_since_prior_order"])

cur.execute("SELECT * FROM products;")
products=pd.DataFrame(cur.fetchall(),columns=["product_id","product_name","aisle_id","department_id"])

cur.execute("SELECT * FROM aisle;")
aisle=pd.DataFrame(cur.fetchall(),columns=["aisle_id","aisle"])

cur.execute("SELECT * FROM departments;")
departments=pd.DataFrame(cur.fetchall(),columns=["department_id","department"])

#
# Plot number of hours when purchases were made
#
plt.hist(orders.order_hour_of_day, bins=range(min(orders.order_hour_of_day), max(orders.order_hour_of_day) + binwidth, binwidth))

orders_per_hour=orders.order_hour_of_day.value_counts()
orders_per_hour=orders_per_hour[orders_per_hour.index.sort_values()]

#plt.hist(orders.order_hour_of_day, bins=range(0,24))
N, bins, patches = plt.hist(orders.order_hour_of_day, bins=range(0,24))
fracs = N.astype(float) / N.max()
norm = colors.Normalize(fracs.min(), fracs.max())
for thisfrac, thispatch in zip(fracs, patches):
    color = plt.cm.viridis(norm(thisfrac))
    thispatch.set_facecolor(color)

plt.xlabel('Hours in the day')
plt.ylabel('Frequency')
plt.title(r'Purchases made during the day')
plt.xlim([0,23])
plt.show()


#
# Plot to compare on which day were the most puchases made.
#
orders_per_day=orders.order_dow.value_counts()
orders_per_day=orders_per_day[orders_per_day.index.sort_values()]

barplot = sns.barplot(x = orders_per_day.index, y = orders_per_day, data =orders_per_day)
barplot.set(xlabel = "Day", ylabel = "Average Total Bill", title = "Total Bill by Day")

plt.bar(orders_per_day.index,orders_per_day,align='center',color="plum")
plt.xlabel('Days of the week')
plt.ylabel('Frequency')
plt.title('Purchases made during the Week')
plt.xticks(orders_per_day.index,["Sun","Mon","Tues","Wed","Thurs","Fri","Sat"])
plt.show()

#
#Plot hour of frequency for each day.
#
day0=orders.loc[orders["order_dow"]==0]

# Plot all of them for all days. probably give plotly a shot.
day1=orders.loc[orders["order_dow"]==1]

day2=orders.loc[orders["order_dow"]==2]

day3=orders.loc[orders["order_dow"]==3]

day4=orders.loc[orders["order_dow"]==4]

day5=orders.loc[orders["order_dow"]==5]

day6=orders.loc[orders["order_dow"]==6]

plt.hist(day0.order_hour_of_day,alpha=0.5,color='#a6cee3')
plt.hist(day1.order_hour_of_day,alpha=0.45,color='#1f78b4')
plt.hist(day2.order_hour_of_day,alpha=0.4,color='#b2df8a')
plt.hist(day3.order_hour_of_day,alpha=0.35,color='#33a02c')
plt.hist(day4.order_hour_of_day,alpha=0.3,color='#fb9a99')
plt.hist(day5.order_hour_of_day,alpha=0.25,color='#e31a1c')
plt.hist(day6.order_hour_of_day,alpha=0.2,color='#67a9cf')

plt.hist((day0.order_hour_of_day,
            day1.order_hour_of_day,
            day2.order_hour_of_day,
            day3.order_hour_of_day,
            day4.order_hour_of_day,
            day5.order_hour_of_day,
            day6.order_hour_of_day
            ))
plt.show()

# TODO: REDO COLORS AND LEGEND
#

# How often to they shop?
#
days_order=orders.days_since_prior_order.value_counts()
days_order=days_order[days_order.index.sort_values()]

plt.bar(days_order.index,days_order,align='center')
plt.xlim([0,31])
plt.show()
#TODO: Make tree map and plots

import plotly.plotly as py
import plotly.graph_objs as go
py.tools.set_credentials_file(username='tariqK', api_key='HIrWXVXWawB0Cix9cq6i')
import squarify

# example

# Set the coordinates
x = 0.
y = 0.
width = 500.
height = 500.
#values of products or sum of products
#values = [500, 433, 78, 25, 25, 7]
# Determine and collect data for most frequent product. WARNING!: opp has 500 rows only!
product_count=opp.product_id.value_counts()

aisle_name=[]
for e in product_count:
    print findProductName(product_count.index[e])
    aisle_name.append(findProductName(product_count.index[e]))
allNames=pd.Series(aisle_name)

#normed = squarify.normalize_sizes(values, width, height)
normed1 = squarify.normalize_sizes(allNames, width, height)
#rects = squarify.squarify(normed, x, y, width, height)
rects1 = squarify.squarify(normed1,x,y,width,height)

# Choose colors from http://colorbrewer2.org/ under "Export"
#color_brewer = ['rgb(166,206,227)','rgb(31,120,180)','rgb(178,223,138)',
#                'rgb(51,160,44)','rgb(251,154,153)','rgb(227,26,28)']

color_brewer1 = ['rgb(239,138,98)','rgb(247,247,247)','rgb(103,169,207)']
bupu500 = cl.interp( color_brewer1, 10 )

def findProductName(val):
    aNum=products.aisle_id[products.product_id==val]
    aNam=aisle.aisle[aisle.aisle_id==int(aNum)].values[0]
    return aNam.strip()

#Make it work first and then switch out the names


shapes = []
annotations = []
counter = 0

for r in rects1:
    shapes.append(
        dict(
            type = 'rect',
            x0 = r['x'],
            y0 = r['y'],
            x1 = r['x']+r['dx'],
            y1 = r['y']+r['dy'],
            line = dict( width = 2 ),
            fillcolor = bupu500[counter]
        )
    )
    annotations.append(
        dict(
            x = r['x']+(r['dx']/2),
            y = r['y']+(r['dy']/2),
            text = allNames.index[counter],
            showarrow = False
        )
    )
    counter = counter + 1
    if counter >= len(allNames):
        counter = 0

# For hover text
trace0 = go.Scatter(
    x = [ r['x']+(r['dx']/2) for r in rects1 ],
    y = [ r['y']+(r['dy']/2) for r in rects1 ],
    text = [ str(v) for v in allNames.index ],
    mode = 'text',
)

layout = dict(
    height=1500,
    width=1500,
    xaxis=dict(showgrid=False,zeroline=False),
    yaxis=dict(showgrid=False,zeroline=False),
    shapes=shapes,
    annotations=annotations,
    hovermode='closest'
)

# With hovertext
figure = dict(data=[trace0], layout=layout)

# Without hovertext
# figure = dict(data=[Scatter()], layout=layout)

py.plot(figure, filename='squarify-treemap')
